program LazArgParseExample;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
    cthreads,
  {$ENDIF}
  Classes,
  SysUtils,
  LazArgParse in '..\LazArgParse.pas';

var
  Parser  : TArgumentParser;
  Args    : TNamespace;
  filename: String;
  mode    : String;
  count   : Integer;
  i       : Integer;
  verbose : Boolean;
begin
  Parser := TArgumentParser.Create(ApplicationName);
  try
    Parser.SetDescription('An example of using LazArgParse for Lazarus.');

    // Add args
    Parser.AddArgument('filename', ''  , ''         , 'The name of the file to process', True);
    Parser.AddArgument('count'   , '-c', '--count'  , 'Number of repetitions'          , False, TArgAction.Store, TArgType.AsInteger, '1');
    Parser.AddArgument('mode'    , '-m', '--mode'   , 'Operating mode'                 , False, TArgAction.Store, TArgType.AsString , 'safe', ['fast', 'safe']);
    Parser.AddArgument('verbose' , '-v', '--verbose', 'Detailed output'                , False, TArgAction.Flag , TArgType.AsBoolean);

    // Parse param args
    Args := Parser.ParamArgs;

    filename := Args.GetAsString('filename');
    count    := Args.GetAsInteger('count');
    verbose  := Args.GetAsBoolean('verbose');
    mode     := Args.GetAsString('mode');

    // Using example
    if verbose then
      Writeln('File: ', filename, ', Repeats: ', count, ', Mode: ', mode);

    for i := 1 to count do
      Writeln(Format('Processing %d/%d file %s in mode %s...', [i, count, filename, mode]));
  except
    on E: Exception do
    begin
      Writeln(E.Message);
      Parser.PrintHelp;   // Print help
    end;
  end;
  Parser.Free;
  readln;
end.


