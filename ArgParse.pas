unit ArgParse;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections;

type
  {$SCOPEDENUMS ON}

  TArgAction = (Store, StoreTrue);

  TArgType = (AsString, AsInteger, AsBoolean);

  EArgumentParserError = class(Exception);

  TArgument = class
  public
    Name: string;           // logical name, e.g. "verbose" or "filename"
    ShortName: string;      // e.g. "-v"
    LongName: string;       // e.g. "--verbose"
    Help: string;
    Required: Boolean;
    Action: TArgAction;
    ArgType: TArgType;
    DefaultValue: string;
    NArgsAll: Boolean;      // if true collect remaining args
    Choices: TArray<string>;
    constructor Create(const AName: string);
  end;

  TNamespace = class
  private
    FValues: TDictionary<string, TArray<string>>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure SetValue(const AName: string; const AValues: TArray<string>);
    function Has(const AName: string): Boolean;
    function GetAsString(const AName: string; const ADefault: string = ''): string;
    function GetAsInteger(const AName: string; ADefault: Integer = 0): Integer;
    function GetAsBoolean(const AName: string; ADefault: Boolean = False): Boolean;
    function GetAll(const AName: string): TArray<string>;
  end;

  TArgumentParser = class
  private
    FProgName: string;
    FDescription: string;
    FArgs: TList<TArgument>;
    FParamArgs: TNamespace;
    procedure RaiseError(const Msg: string);
    function FindByFlag(const AFlag: string): TArgument;
    function IsFlag(const S: string): Boolean;
    function GetParamArgs: TNamespace;
  public
    constructor Create(const AProgName: string = 'program');
    destructor Destroy; override;
    procedure SetDescription(const ADesc: string);
    function AddArgument(const AName: string; const AShort: string = ''; const ALong: string = ''; AHelp: string = ''; ARequired: Boolean = False; AAction: TArgAction = TArgAction.Store; AArgType: TArgType = TArgType.AsString; const ADefault: string = ''; ANargsAll: Boolean = False; const AChoices: TArray<string> = []): TArgument;

    function ParseArgs(const ARawArgs: TArray<string>): TNamespace;
    property ParamArgs: TNamespace read GetParamArgs;  // uses ParamStr/ParamCount
    procedure PrintHelp;
  end;

implementation

{ TArgument }

constructor TArgument.Create(const AName: string);
begin
  inherited Create;
  Name := AName;
  ShortName := '';
  LongName := '';
  Help := '';
  Required := False;
  Action := TArgAction.Store;
  ArgType := TArgType.AsString;
  DefaultValue := '';
  NArgsAll := False;
  Choices := [];
end;

{ TNamespace }

constructor TNamespace.Create;
begin
  inherited Create;
  FValues := TDictionary<string, TArray<string>>.Create;
end;

destructor TNamespace.Destroy;
begin
  FValues.Free;
  inherited;
end;

procedure TNamespace.SetValue(const AName: string; const AValues: TArray<string>);
begin
  FValues.AddOrSetValue(AName, AValues);
end;

function TNamespace.Has(const AName: string): Boolean;
begin
  Result := FValues.ContainsKey(AName);
end;

function TNamespace.GetAll(const AName: string): TArray<string>;
begin
  if not FValues.TryGetValue(AName, Result) then
    Result := [];
end;

function TNamespace.GetAsBoolean(const AName: string; ADefault: Boolean): Boolean;
begin
  var Value: TArray<string>;
  if FValues.TryGetValue(AName, Value) then
  begin
    if Length(Value) = 0 then
      Exit(True);
    Result := (Value[0] <> '0') and (Value[0].ToLower <> 'false');
  end
  else
    Result := ADefault;
end;

function TNamespace.GetAsInteger(const AName: string; ADefault: Integer): Integer;
begin
  var Value: TArray<string>;
  if FValues.TryGetValue(AName, Value) and (Length(Value) > 0) then
  try
    Result := Value[0].ToInteger;
  except
    Result := ADefault;
  end
  else
    Result := ADefault;
end;

function TNamespace.GetAsString(const AName: string; const ADefault: string): string;
begin
  var Value: TArray<string>;
  if FValues.TryGetValue(AName, Value) and (Length(Value) > 0) then
    Result := Value[0]
  else
    Result := ADefault;
end;

{ TArgumentParser }

constructor TArgumentParser.Create(const AProgName: string);
begin
  inherited Create;
  FParamArgs := nil;
  FProgName := AProgName;
  FDescription := '';
  FArgs := TList<TArgument>.Create;
end;

destructor TArgumentParser.Destroy;
begin
  for var Arg in FArgs do
    Arg.Free;
  FArgs.Free;
  FParamArgs.Free;
  inherited;
end;

procedure TArgumentParser.RaiseError(const Msg: string);
begin
  raise EArgumentParserError.Create('ArgumentParser error: ' + Msg);
end;

procedure TArgumentParser.SetDescription(const ADesc: string);
begin
  FDescription := ADesc;
end;

function TArgumentParser.AddArgument(const AName: string; const AShort: string; const ALong: string; AHelp: string; ARequired: Boolean; AAction: TArgAction; AArgType: TArgType; const ADefault: string; ANargsAll: Boolean; const AChoices: TArray<string>): TArgument;
begin
  Result := TArgument.Create(AName);
  FArgs.Add(Result);
  Result.ShortName := AShort;
  Result.LongName := ALong;
  Result.Help := AHelp;
  Result.Required := ARequired;
  Result.Action := AAction;
  Result.ArgType := AArgType;
  Result.DefaultValue := ADefault;
  Result.NArgsAll := ANargsAll;
  Result.Choices := Copy(AChoices);
end;

function TArgumentParser.IsFlag(const S: string): Boolean;
begin
  Result := (Length(S) > 0) and (S[1] = '-')
end;

function TArgumentParser.FindByFlag(const AFlag: string): TArgument;
begin
  for var Arg in FArgs do
  begin
    if (Arg.ShortName <> '') and (Arg.ShortName = AFlag) then
      Exit(Arg);
    if (Arg.LongName <> '') and (Arg.LongName = AFlag) then
      Exit(Arg);
  end;
  Result := nil;
end;

function TArgumentParser.ParseArgs(const ARawArgs: TArray<string>): TNamespace;
begin
  Result := TNamespace.Create;
  try
    for var Arg in FArgs do
      if Arg.DefaultValue <> '' then
        Result.SetValue(Arg.Name, [Arg.DefaultValue]);

    var i: integer := 0;
    while i < Length(ARawArgs) do
    begin
      var Token := ARawArgs[i];
      if IsFlag(Token) then
      begin
        var Arg := FindByFlag(Token);
        if Arg = nil then
          RaiseError('Unknown option: ' + Token);

        if Arg.Action = TArgAction.StoreTrue then
        begin
          Result.SetValue(Arg.Name, []); // presence -> true
          Inc(i);
          Continue;
        end;

        // store value(s)
        if Arg.NArgsAll then
        begin
          var j := i + 1;
          var Collected: TArray<string> := [];
          while (j < Length(ARawArgs)) and (not IsFlag(ARawArgs[j])) do
          begin
            Collected := Collected + [ARawArgs[j]];
            Inc(j);
          end;
          Result.SetValue(Arg.Name, Collected);
          i := j;
          Continue;
        end
        else
        begin
          if i + 1 >= Length(ARawArgs) then
            RaiseError('Option ' + Token + ' requires a value');

          // validate choices
          if Length(Arg.Choices) > 0 then
          begin
            var Found := False;
            for var Choise in Arg.Choices do
              if Choise = ARawArgs[i + 1] then
              begin
                Found := True;
                Break;
              end;
            if not Found then
              RaiseError(Format('Value for %s not in choices', [Token]));
          end;

          Result.SetValue(Arg.Name, [ARawArgs[i + 1]]);
          Inc(i, 2);
          Continue;
        end;
      end
      else
      begin
        // positional arguments: match against first argument with no flags
        var Found := False;
        for var Arg in FArgs do
          if (Arg.ShortName = '') and (Arg.LongName = '') then
            if not Result.Has(Arg.Name) then
            begin
              Result.SetValue(Arg.Name, [Token]);
              Found := True;
              Break;
            end;
        if not Found then
          RaiseError('Unexpected positional argument: ' + Token);
        Inc(i);
      end;
    end;

    // check required
    for var Arg in FArgs do
      if Arg.Required and not Result.Has(Arg.Name) then
        RaiseError('Argument required: ' + Arg.Name);

    // For flags with action store_true that were not set, put false
    for var Arg in FArgs do
      if (Arg.Action = TArgAction.StoreTrue) and not Result.Has(Arg.Name) then
        Result.SetValue(Arg.Name, ['0']);
  except
    Result.Free;
    raise;
  end;
end;

function TArgumentParser.GetParamArgs: TNamespace;
begin
  if not Assigned(FParamArgs) then
  begin
    var Args: TArray<string>;
    for var i := 1 to ParamCount do
      Args := Args + [ParamStr(i)];
    FParamArgs := ParseArgs(Args);
  end;
  Result := FParamArgs;
end;

procedure TArgumentParser.PrintHelp;
begin
  Writeln('Usage: ', FProgName, ' [options]');
  if FDescription <> '' then
    Writeln(FDescription);
  Writeln;
  Writeln('Options:');
  for var Arg in FArgs do
  begin
    var Flags := '';
    if Arg.ShortName <> '' then
      Flags := Flags + Arg.ShortName;
    if Arg.LongName <> '' then
    begin
      if Flags <> '' then
        Flags := Flags + ', ';
      Flags := Flags + Arg.LongName;
    end;
    if Flags = '' then
      Flags := Arg.Name;
    Writeln(Format('  %-20s %s', [Flags, Arg.Help]));
  end;
end;

end.

