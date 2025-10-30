unit LazArgParse;

{$mode objfpc}{$H+}
{$SCOPEDENUMS ON}

interface

uses
  SysUtils, Classes, fgl, Types;

type

  TArgAction = (
    /// <summary>
    /// Expects a value after the flag (for example, --count 5).
    /// </summary>
    Store,
    /// <summary>
    /// A boolean flag that is set to True if present (for example, --verbose).
    /// </summary>
    Flag
  );

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
    Choices: TStringDynArray;
    constructor Create(const AName: string);
  end;

  TNamespace = class
  private
    FValues: specialize TFPGMap<string, TStringDynArray>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure SetValue(const AName: string; const AValues: TStringDynArray);
    function Has(const AName: string): Boolean;
    function GetAsString(const AName: string; const ADefault: string = ''): string;
    function GetAsInteger(const AName: string; ADefault: Integer = 0): Integer;
    function GetAsBoolean(const AName: string; ADefault: Boolean = False): Boolean;
    function GetAll(const AName: string): TStringDynArray;
  end;

  IArgumentParser = interface
    ['{641E3306-0498-49D3-B835-6458FE69412D}']
    function GetParamArgs: TNamespace;
    /// <summary>
    /// Adds a description of the use of the program
    /// </summary>
    procedure SetDescription(const ADesc: string);
    /// <summary>
    /// Adds a new command-line argument to the parser.
    /// </summary>
    /// <param name="AName">
    /// The logical name of the argument, which is then used to retrieve the value through Namespace (for example, 'filename')
    /// </param>
    /// <param name="AShort">
    /// A short flag that starts with '-', such as '-v'. It can be empty.
    /// </param>
    /// <param name="ALong">
    /// A long flag that starts with '--', such as '--verbose'. It can be empty.
    /// </param>
    /// <param name="AHelp">
    /// The help text displayed in the PrintHelp method.
    /// </param>
    /// <param name="ARequired">
    /// The requiredness of the argument. If True and the argument is not specified, it will cause an error.
    /// </param>
    /// <param name="AAction">
    /// Defines the behavior when a flag:
    /// Store - expects a value after the flag (for example, --count 5).
    /// Flag � a boolean flag that is set to True if present (for example, --verbose).
    /// </param>
    /// <param name="AArgType">
    /// The type of the value: AsString, AsInteger, AsBoolean. It is used when reading the value.
    /// </param>
    /// <param name="ADefault">
    /// The default value if the argument is not specified.
    /// </param>
    /// <param name="AChoices">
    /// An array of valid values. If specified, the input is checked for matching one of the elements.
    /// </param>
    function AddArgument(const AName: string; const AShort: string = ''; const ALong: string = ''; const AHelp: string = ''; const ARequired: Boolean = False; const AAction: TArgAction = TArgAction.Store; const AArgType: TArgType = TArgType.AsString; const ADefault: string = ''; const AChoices: TStringDynArray = Default(TStringDynArray)): TArgument;
    /// <summary>
    /// Parsing the parameter list. Returns a separate object
    /// </summary>
    function ParseArgs(const ARawArgs: TStringDynArray): TNamespace;
    /// <summary>
    /// Gives access to the program run parameters (ParamStr/ParamCount)
    /// </summary>
    property ParamArgs: TNamespace read GetParamArgs;
    /// <summary>
    /// Displays help on startup parameters
    /// </summary>
    procedure PrintHelp(AReadLn: Boolean = False);
  end;

  TArgumentParser = class(TInterfacedObject, IArgumentParser)
  private
    FProgName: string;
    FDescription: string;
    FArgs: specialize TFPGObjectList<TArgument>;
    FParamArgs: TNamespace;
    procedure RaiseError(const Msg: string);
    function FindByFlag(const AFlag: string): TArgument;
    function IsFlag(const S: string): Boolean;
    function GetParamArgs: TNamespace;
  public
    /// <param name="AProgName">
    /// The name of the executive file for reference
    /// </param>
    constructor Create(const AProgName: string = 'program');
    destructor Destroy; override;
    /// <summary>
    /// Adds a description of the use of the program
    /// </summary>
    procedure SetDescription(const ADesc: string);
    /// <summary>
    /// Adds a new command-line argument to the parser.
    /// </summary>
    /// <param name="AName">
    /// The logical name of the argument, which is then used to retrieve the value through Namespace (for example, 'filename')
    /// </param>
    /// <param name="AShort">
    /// A short flag that starts with '-', such as '-v'. It can be empty.
    /// </param>
    /// <param name="ALong">
    /// A long flag that starts with '--', such as '--verbose'. It can be empty.
    /// </param>
    /// <param name="AHelp">
    /// The help text displayed in the PrintHelp method.
    /// </param>
    /// <param name="ARequired">
    /// The requiredness of the argument. If True and the argument is not specified, it will cause an error.
    /// </param>
    /// <param name="AAction">
    /// Defines the behavior when a flag:
    /// Store - expects a value after the flag (for example, --count 5).
    /// Flag � a boolean flag that is set to True if present (for example, --verbose).
    /// </param>
    /// <param name="AArgType">
    /// The type of the value: AsString, AsInteger, AsBoolean. It is used when reading the value.
    /// </param>
    /// <param name="ADefault">
    /// The default value if the argument is not specified.
    /// </param>
    /// <param name="AChoices">
    /// An array of valid values. If specified, the input is checked for matching one of the elements.
    /// </param>
    function AddArgument(const AName: string; const AShort: string = ''; const ALong: string = ''; const AHelp: string = ''; const ARequired: Boolean = False; const AAction: TArgAction = TArgAction.Store; const AArgType: TArgType = TArgType.AsString; const ADefault: string = ''; const AChoices: TStringDynArray = Default(TStringDynArray)): TArgument;
    /// <summary>
    /// Parsing the parameter list. Returns a separate object
    /// </summary>
    function ParseArgs(const ARawArgs: TStringDynArray): TNamespace;
    /// <summary>
    /// Gives access to the program run parameters (ParamStr/ParamCount)
    /// </summary>
    property ParamArgs: TNamespace read GetParamArgs;
    /// <summary>
    /// Displays help on startup parameters
    /// </summary>
    procedure PrintHelp(AReadLn: Boolean = False);
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
  Choices := [];
end;

{ TNamespace }

constructor TNamespace.Create;
begin
  inherited Create;
  FValues := specialize TFPGMap<string, TStringDynArray>.Create;
end;

destructor TNamespace.Destroy;
begin
  FValues.Free;
  inherited;
end;

procedure TNamespace.SetValue(const AName: string; const AValues: TStringDynArray);
begin
  FValues.AddOrSetData(AName, AValues);
end;

function TNamespace.Has(const AName: string): Boolean;
begin
  Result := FValues.IndexOf(AName) <> -1;
end;

function TNamespace.GetAll(const AName: string): TStringDynArray;
begin
  if not FValues.TryGetData(AName, Result) then
    Result := [];
end;

function TNamespace.GetAsBoolean(const AName: string; ADefault: Boolean): Boolean;
var
  Value: TStringDynArray;
begin
  if FValues.TryGetData(AName, Value) then
  begin
    if Length(Value) = 0 then
      Exit(True);
    Result := (Value[0] <> '0') and (Value[0].ToLower <> 'false');
  end
  else
    Result := ADefault;
end;

function TNamespace.GetAsInteger(const AName: string; ADefault: Integer): Integer;
var
  Value: TStringDynArray;
begin
  if FValues.TryGetData(AName, Value) and (Length(Value) > 0) then
  try
    Result := Value[0].ToInteger;
  except
    Result := ADefault;
  end
  else
    Result := ADefault;
end;

function TNamespace.GetAsString(const AName: string; const ADefault: string): string;
var
  Value: TStringDynArray;
begin
  if FValues.TryGetData(AName, Value) and (Length(Value) > 0) then
    Result := Value[0]
  else
    Result := ADefault;
end;

{ TArgumentParser }

constructor TArgumentParser.Create(const AProgName: string);
type
  TArgumentList = specialize TFPGObjectList<TArgument>;
begin
  inherited Create;
  FParamArgs := nil;
  FProgName := AProgName;
  FDescription := '';
  FArgs := TArgumentList.Create;
end;

destructor TArgumentParser.Destroy;
begin
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

function TArgumentParser.AddArgument(const AName: string; const AShort: string; const ALong: string; const AHelp: string; const ARequired: Boolean; const AAction: TArgAction; const AArgType: TArgType; const ADefault: string; const AChoices: TStringDynArray): TArgument;
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
  Result.Choices := Copy(AChoices);
end;

function TArgumentParser.IsFlag(const S: string): Boolean;
begin
  Result := (Length(S) > 0) and (S[1] = '-')
end;

function TArgumentParser.FindByFlag(const AFlag: string): TArgument;
var
  Arg: TArgument;
begin
  for Arg in FArgs do
  begin
    if (Arg.ShortName <> '') and (Arg.ShortName = AFlag) then
      Exit(Arg);
    if (Arg.LongName <> '') and (Arg.LongName = AFlag) then
      Exit(Arg);
  end;
  Result := nil;
end;

function TArgumentParser.ParseArgs(const ARawArgs: TStringDynArray): TNamespace;
var
  Arg     : TArgument;
  ArgValue: String;
  Choise  : String;
  Token   : String;
  i       : integer = 0;
  Found   : Boolean;
begin
  Result := TNamespace.Create;
  try
    for Arg in FArgs do
      if Arg.DefaultValue <> '' then
        Result.SetValue(Arg.Name, [Arg.DefaultValue]);

    while i < Length(ARawArgs) do
    begin
      Token := ARawArgs[i];
      if IsFlag(Token) then
      begin
        Arg := FindByFlag(Token);
        if Arg = nil then
          RaiseError('Unknown option: ' + Token);

        if Arg.Action = TArgAction.Flag then
        begin
          Result.SetValue(Arg.Name, []); // presence -> true
          Inc(i);
          Continue;
        end;

        // store value(s)
        if i + 1 >= Length(ARawArgs) then
          RaiseError('Option ' + Token + ' requires a value');

        ArgValue := ARawArgs[i + 1];

        // validate choices
        if Length(Arg.Choices) > 0 then
        begin
          Found := False;
          for Choise in Arg.Choices do
            if Choise = ArgValue then
            begin
              Found := True;
              Break;
            end;
          if not Found then
            RaiseError(Format('Value for %s not in choices: %s', [Token, string.Join('|', Arg.Choices)]));
        end;

        // validate type
        case Arg.ArgType of
          TArgType.AsInteger:
            try
              ArgValue.ToInt64;
            except
              RaiseError(Format('Value for %s must be Integer', [Token]));
            end;
          TArgType.AsBoolean:
            begin
              if (Pos(ArgValue.ToLower, 'true' + 'false' + '1' + '0') = -1) then
                RaiseError(Format('Value for %s must be Boolean', [Token]));
            end;
        end;

        Result.SetValue(Arg.Name, [ArgValue]);
        Inc(i, 2);
        Continue;
      end
      else
      begin
        // positional arguments: match against first argument with no flags
        Found := False;
        for Arg in FArgs do
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
    for Arg in FArgs do
      if Arg.Required and not Result.Has(Arg.Name) then
        RaiseError('Argument required: ' + Arg.Name);

    // For flags with action store_true that were not set, put false
    for Arg in FArgs do
      if (Arg.Action = TArgAction.Flag) and not Result.Has(Arg.Name) then
        Result.SetValue(Arg.Name, ['0']);
  except
    Result.Free;
    raise;
  end;
end;

function TArgumentParser.GetParamArgs: TNamespace;
var
  Args: TStringDynArray;
  i   : Integer;
begin
  Args := [];
  if not Assigned(FParamArgs) then
  begin
    for i := 1 to ParamCount do
      Args := Concat(Args, [ParamStr(i)]);
    FParamArgs := ParseArgs(Args);
  end;
  Result := FParamArgs;
end;

procedure TArgumentParser.PrintHelp(AReadLn: Boolean);
var
  Arg  : TArgument;
  Flags: String;
  Help : String;
begin
  Writeln('Usage: ', FProgName, ' [options]');
  if FDescription <> '' then
    Writeln(FDescription);
  Writeln;
  Writeln('Options:');
  for Arg in FArgs do
  begin
    Flags := '';
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
    Help := Arg.Help;
    if Length(Arg.Choices) > 0 then
      Help := Help + ' (' + string.Join('|', Arg.Choices) + ')';
    Writeln(Format('  %-20s %s', [Flags, Help]));
  end;
  if AReadLn then
    Readln;
end;

end.

