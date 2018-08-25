(*
  Implementing Destructor for a Record & Detecting a Copy Operation without memory
  consumption penalty
  Copyright (c) 2018 Michel Podvin

  MIT License
  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:
  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
*)
unit DestroyRec;

interface
{$O+}
//uses classes, dialogs ;

type
  PStackFrame = ^TStackFrame;
  TStackFrame = packed record  // Stack frame identical in Delphi 6,7,XE4
    Ebp:Pointer;
    ReturnAdr:Pointer;
    Self:Pointer; //IInterface source
    Dest:Pointer; //Ptr to IInterface Dest
    Self2:Pointer;//IInterface source
  end;

  PDestroyRec = ^TDestroyRec;
  TDestroyRec = packed record
  private
    procedure _FixNullRec(PStack:PStackFrame);
    function _ReleaseToFix:Integer;stdcall;// for uninitialized record only
  private
    function _AddRef:Integer;stdcall;
    function _Release:Integer;stdcall;
  private
    VMT:Pointer;  // should be the first!
    Unknown:IInterface;
  private
    //
    Value:Integer;
  public
    constructor Create(AValue:Integer);
    procedure Init;
    procedure Destroy;
  end;

implementation

const
  PSEUDO_VMT:array[0..2] of Pointer  = (nil, @TDestroyRec._AddRef, @TDestroyRec._Release);
  NULLREC_VMT:array[0..2] of Pointer = (nil, nil, @TDestroyRec._ReleaseToFix);

{ TDestroyRec }

procedure TDestroyRec.Init;
begin
  Value := 0;//for debug
  Pointer(Unknown) := @VMT;
  VMT              := @PSEUDO_VMT;
end;

constructor TDestroyRec.Create(AValue: Integer);
begin
  Init;
  Value := AValue;
end;

procedure TDestroyRec.Destroy;
begin
  //THE DESTROY
end;

procedure TDestroyRec._FixNullRec(PStack: PStackFrame);
begin
  // TODO assert in a dummy record in an 'initialized' block (one-shot)
  Assert((PStack^.Self = @VMT) and (PStack^.Self = PStack^.Self2), 'Bad Stack Frame !' );
  // Detect uninitialized record
  if Assigned(PStack^.Dest) then
  begin
    // Adjust the address (to retrieve Self)
    // All-round version or do PStack^.Dest-Sizeof(Pointer)
    with PDestroyRec(PByte(PStack^.Dest)-(Integer(@TDestroyRec(nil^).Unknown)-Integer(@TDestroyRec(nil^).VMT)))^ do
      if Pointer(Unknown) = nil then // Uninitialized record ?
      begin
        Pointer(Unknown) := @VMT; // Fix it!
        VMT              := @NULLREC_VMT; //to identify it
      end;
  end;
end;

function TDestroyRec._AddRef: Integer;
var
  PStack:PStackFrame;
begin
  asm
    mov PStack, ebp
  end;
  _FixNullRec(PStack);
  // Insert your code here
  Result := 0;
end;

function TDestroyRec._Release: Integer;// Copy
begin
  // Initialized record
  Pointer(Unknown) := @VMT; // copy, so fix the ptr (because is perhaps a ptr to the stack)
  Destroy;
  Result := 0;
end;

// For uninitialized record only
function TDestroyRec._ReleaseToFix: Integer;
begin
  Pointer(Unknown) := @VMT;// Fix it!
  VMT := @PSEUDO_VMT;// Readjust it (Uninitialized record)
  Result := 0;
end;

end.
