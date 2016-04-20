Yaml(YamlText,IsFile=1,YamlObj=0){ ; Version 1.0.0.17 http://www.autohotkey.com/forum/viewtopic.php?t=70559
  static
  static base:={Dump:"Yaml_Dump",Save:"Yaml_Save",Add:"Yaml_Add",Merge:"Yaml_Merge",__Delete:"__Delete",_Insert:"_Insert",_Remove:"_Remove",_GetCapacity:"_GetCapacity",_SetCapacity:"_SetCapacity",_GetAddress:"_GetAddress",_MaxIndex:"_MaxIndex",_MinIndex:"_MinIndex",_NewEnum:"_NewEnum",_HasKey:"_HasKey",_Clone:"_Clone",Insert:"Insert",Remove:"Remove",GetCapacity:"GetCapacity",SetCapacity:"SetCapacity",GetAddress:"GetAddress",MaxIndex:"MaxIndex",MinIndex:"MinIndex",NewEnum:"NewEnum",HasKey:"HasKey",Clone:"Clone",base:{__Call:"Yaml_Call"}}
  static BackupVars:="LVL,SEQ,KEY,SCA,TYP,VAL,CMT,LFL,CNT",IncompleteSeqMap
  local maxLVL:=0,LastContObj:=0,LastContKEY:=0,LinesAdded:=0,_LVLChanged:=0,_LVL,_SEQ,_KEY,_SCA,_TYP,_VAL,_CMT,_LFL,_CNT,_NXT,__LVL,__SEQ,__KEY,__SCA,__TYP,__VAL,__CMT,__LFL,__CNT,__NXT
  AutoTrim % ((AutoTrim:=A_AutoTrim)="On")?"Off":"Off"
  LVL0:=pYaml:=YamlObj?YamlObj:Object("base",base),__LVL:=0,__LVL0:=0
  If IsFile
    FileRead,YamlText,%YamlText%
  Loop,Parse,YamlText,`n,`r
  {
    If (!_CNT && (A_LoopField=""||RegExMatch(A_LoopField,"^\s+$"))){ ;&&__KEY=""&&__SEQ="")){
			If ((OBJ:=LVL%__LVL%[""].MaxIndex())&&IsObject(LVL%__LVL%["",OBJ])&&__SEQ){
				If (__KEY!="")
					Yaml_Continue(LastContObj:=LVL%__LVL%["",Obj],LastContKEY:=__key,"",__SCA)
				else Yaml_Continue(LastContObj:=LVL%__LVL%[""],LastContKEY:=Obj,"",__SCA,__SEQ)
			} else If (__SEQ && OBJ){
				Yaml_Continue(LastContObj:=LVL%__LVL%[""],LastContKEY:=OBJ,"",__SCA,__SEQ)
			} else If (OBJ){
				Yaml_Continue(LastContObj:=LVL%__LVL%[""],LastContKEY:=OBJ,"",__SCA,1)
			} else if (__KEY!="")
				Yaml_Continue(LastContObj:=LVL%__LVL%,LastContKEY:=__KEY,"",__SCA)
			else LinesAdded--
			LinesAdded++
      Continue
    } else If (!_CNT && LastContObj
    && ( RegExMatch(A_LoopField,"^(---)?\s*?(-\s)?("".+""\s*:\s|'.+'\s*:\s|[^:""'\{\[]+\s*:\s)")
    || RegExMatch(A_LoopField,"^(---)|\s*(-\s)") )){
			If !__SCA
        LastContObj[LastContKEY]:=SubStr(LastContObj[LastContKEY],1,-1*LinesAdded)
      LastContObj:=0,LastContKEY:=0,LinesAdded:=0
    }
    If InStr(A_LoopField,"#"){
      If (RegexMatch(A_LoopField,"^\s*#.*") || InStr(A_LoopField,"%YAML")=1) ;Comments only, do not parse
        continue
      else if Yaml_IsQuoted(LTrim(A_LoopField,"- ")) || RegExMatch(A_LoopField,"(---)?\s*?(-\s)?("".+""\s*:\s|'.+'\s*:\s|[^:""'\{\[]+\s*:\s)\s*([\|\>][+-]?)?\s*(!!\w+\s)?\s*("".+|'.+)$")&&!RegExMatch(A_LoopField,"[^\\]""\s+#")
        LoopField:=A_LoopField
      else if RegExMatch(A_LoopField,"\s+#.*$","",RegExMatch(A_LoopField,"(---)?\s*?(-\s)?("".+""\s*:\s|'.+'\s*:\s|[^:""'\{\[]+\s*:\s)?\s*([\|\>][+-]?)?\s*(!!\w+\s)?\s*("".+""|'.+')?\K")-1)
        LoopField:=SubStr(A_LoopField,1,RegExMatch(A_LoopField,"\s+#.*$","",RegExMatch(A_LoopField,"(---)?\s*?(-\s)?("".+""\s*:\s|'.+'\s*:\s|[^:""'\{\[]+\s*:\s)?\s*([\|\>][+-]?)?\s*(!!\w+\s)?\s*("".+""|'.+')?\K")-1)-1)
      else LoopField:=A_LoopField
    } else LoopField:=A_LoopField
    If _CNT {
      If Yaml_IsSeqMap(RegExReplace(IncompleteSeqMap LoopField,"^(\s+)?(-\s)?("".+""\s*:\s|'.+'\s*:\s|[^:""'\{\[]+\s*:\s)?"))
        LoopField:=IncompleteSeqMap LoopField,_CNT:=0,IncompleteSeqMap:=""
      else {
				IncompleteSeqMap.=LoopField
				continue
			}
    }
    If (LoopField="---"){
      Loop % (maxLVL)
        LVL%A_Index%:=""
      Loop,Parse,BackupVars,`,
        __%A_LoopField%:="",__%A_LoopField%0:=""
      Loop,Parse,BackupVars,`,
        Loop % maxLVL
        __%A_LoopField%%A_Index%:=""
      maxLVL:=0
      __LVL:=0,__LVL0:=0
      If !IsObject(pYaml[""])
        pYaml[""]:=LVL0:=Object("base",base)
      pYaml[""].Insert(LVL0:=Object("base",base))
      Continue
    } else if (LoopField="..."){
      LVL0:=pYaml
      Loop % maxLVL
        LVL%A_Index%:=""
      Loop,Parse,BackupVars,`,
        __%A_LoopField%:="",__%A_LoopField%0:=""
      Loop,Parse,BackupVars,`,
        Loop % maxLVL
        __%A_LoopField%%A_Index%:=""
      maxLVL:=0
      __LVL:=0,__LVL0:=0
      Continue
    }
    If (SubStr(LoopField,0)=":")
      LoopField.=A_Space ; add space to force RegEx to match even if the value and space after collon is missing e.g. Object:`n  objects item
    RegExMatch(LoopField,"S)^(?<LVL>\s+)?(?<SEQ>-\s)?(?<KEY>"".+""\s*:\s|'.+'\s*:\s|[^:""'\{\[]+\s*:\s)?\s*(?<SCA>[\|\>][+-]?)?\s*(?<TYP>!!\w+\s)?\s*(?<VAL>"".+""|'.+'|.+)?\s*$",_)
		If _KEY ;cut off (:)
     StringTrimRight,_KEY,_KEY,2
    _KEY:=Yaml_UnQuoteIfNeed(_KEY)
    If IsVal:=Yaml_IsQuoted(_VAL)
			_VAL:=Yaml_UnQuoteIfNeed(_VAL)
    ;determine current level
    _LVL:=Yaml_S2I(_LVL)
    If _LVL-__LVL>1||(_LVL>__LVL&&_LVLChanged) ;&&!(__SEQ&&__KEY!=""&&_KEY!="")) ; (__SEQ?2:1)
    {
      Loop % (_LVLChanged?_LVL-_LVLChanged:_LVL-__LVL-1)
        LoopField:=SubStr(LoopField,SubStr(LoopField,1,1)=A_Tab?1:2)
      _LVL:=_LVLChanged?_LVLChanged:__LVL+1,_LVLChanged:=_LVLChanged?_LVLChanged:_LVL ;__LVL%_LVL%:=__LVL%_NXT% ; (__SEQ?2:1)
    } else if _LVLChanged
      _LVL:=_LVLChanged
    else _LVLChanged:=0
    If (maxLVL<_LVL)
      maxLVL:=_LVL+(_SEQ?1:0)
    ; Cut off the leading tabs/spaces conform _LVL
    SubStr:=0,Tabs:=0
    Loop,Parse,LoopField
      If (_LVL*2=SubStr || !SubStr:=SubStr+(A_LoopField=A_Tab?2:1)), Tabs:=Tabs+(A_LoopField=A_Tab?1:0)
        break
    _LFL:=SubStr(LoopField,SubStr-Tabs+1+(_SEQ?2:0))
    _LFL:=Yaml_UnQuoteIfNeed(_LFL)
    _NXT:=_LVL+1 ;next indentation level
    __NXT:=_NXT+1
    _PRV:=_LVL=0?0:_LVL-1
    Loop,Parse,BackupVars,`,
      __%A_LoopField%:=__%A_LoopField%%_PRV%
    If RegExMatch(_LFL,"^-\s*$"){
      _SEQ:="-",_KEY:="",_VAL:=""
    }
    If (!IsVal && !_CNT && (_CNT:=Yaml_Incomplete(Trim(_LFL))||Yaml_Incomplete(Trim(_VAL)))){
      IncompleteSeqMap:=LoopField
      continue
    }
    If (_LVL<__LVL){ ;Reset Objects and Backup vars
      Loop % (maxLVL)
        If (A_Index>_LVL){
          Loop,Parse,BackupVars,`,
            __%A_LoopField%%maxLVL%:=""
          LVL%A_Index%:="",maxLVL:=maxLVL-1
        }
      If (_LVL=0 && !__LVL:=__LVL0:=0)
        Loop,Parse,BackupVars,`,
          __%A_LoopField%:="",__%A_LoopField%0:=""
    }
    If (_SEQ&&_LVL>__LVL&&(__VAL!=""||__SCA))
      _SEQ:="",_KEY:="",_VAL:="",_LFL:="- " _LFL
    If (__CNT)||(_LVL>__LVL&&(__KEY!=""&&_KEY="")&&(__VAL!=""||__SCA))||(__SEQ&&__SCA)
      _KEY:="",_VAL:=""
    If (__CNT||(_LVL>__LVL&&(__KEY!=""||(__SEQ&&(__LFL||__SCA)&&!Yaml_IsSeqMap(__LFL)))&&!(_SEQ||_KEY!=""))){
			If ((OBJ:=LVL%__LVL%[""].MaxIndex())&&IsObject(LVL%__LVL%["",OBJ])&&__SEQ){
        If __KEY!=
          Yaml_Continue(LVL%__LVL%["",Obj],__key,_LFL,__SCA),__CNT:=Yaml_SeqMap(LVL%__LVL%["",OBJ],__KEY,LVL%__LVL%["",OBJ,__KEY])?"":__CNT
        else Yaml_Continue(LVL%__LVL%[""],Obj,_LFL,__SCA,__SEQ),__CNT:=Yaml_SeqMap(LVL%__LVL%[""],OBJ,LVL%__LVL%["",OBJ],__SEQ)?"":__CNT
      } else If (__SEQ && OBJ){
        Yaml_Continue(LVL%__LVL%[""],Obj,_LFL,__SCA,__SEQ)
        __CNT:=Yaml_SeqMap(LVL%__LVL%[""],OBJ,LVL%__LVL%["",OBJ],__SEQ)?"":__CNT
      } else If (OBJ && __KEY=""){
        Yaml_Continue(LVL%__LVL%[""],OBJ,_LFL,__SCA,1)
        __CNT:=Yaml_SeqMap(LVL%__LVL%[""],OBJ,LVL%__LVL%["",OBJ],1)?"":__CNT
      } else {
        Yaml_Continue(LVL%__LVL%,__KEY,_LFL,__SCA)
        __CNT:=Yaml_SeqMap(LVL%__LVL%,__KEY,LVL%__LVL%[__KEY])?"":__CNT
      }
      Continue
    }
    ;Create sequence or map
    If (__SEQ&&(_LVL>__LVL)&&_KEY!=""&&__KEY!=""){
			OBJ:=LVL%__LVL%[""].MaxIndex()
      If _SEQ {
          If !Yaml_SeqMap(LVL%_LVL%["",OBJ,__KEY,""],_KEY,_VAL){
            If !IsObject(LVL%__LVL%["",OBJ,__KEY,""])
              LVL%__LVL%["",OBJ,__KEY,""]:={base:base}
            LVL%__LVL%["",OBJ,__KEY,""].Insert({(_KEY):_VAL!=""?_VAL:(LVL%_NXT%:={base:base}),base:base})
          }
      } else If !Yaml_SeqMap(LVL%_LVL%["",OBJ],_KEY,_VAL){
        LVL%__LVL%["",OBJ,_KEY]:=_VAL!=""?_VAL:(LVL%_NXT%:={base:base})
			}
      If _VAL!=
        continue
    } else If (_SEQ){
      If !IsObject(LVL%_LVL%[""])
        LVL%_LVL%[""]:=Object("base",base)
      While (SubStr(_LFL,1,2)="- "){
        _LFL:=SubStr(_LFL,3),_KEY:=(_KEY!="")?_LFL:=SubStr(_KEY,3):_KEY,LVL%_LVL%[""].Insert(LVL%_NXT%:=Object("",Object("base",base),"base",base)),_LVL:=_LVL+1,_NXT:=_NXT+1,__NXT:=_NXT+1,_PRV:=_LVL-1,maxLVL:=(maxLVL<_LVL)?_LVL:maxLVL
        Loop,Parse,BackupVars,`,
          __%A_LoopField%:=_%A_LoopField%
          ,__%A_LoopField%%_PRV%:=_%A_LoopField%
      }
      If (_KEY="" && _VAL="" && !IsVal){
        If !Yaml_SeqMap(LVL%_LVL%[""],"",_LFL)
          LVL%_LVL%[""].Insert(LVL%_NXT%:=Object("base",base))
      } else If (_KEY!="") {
        LVL%_LVL%[""].Insert(LVL%__NXT%:=Object(_KEY,LVL%_NXT%:=Object("base",base),"base",base))
        If !Yaml_SeqMap(LVL%__NXT%,_KEY,_VAL){
          LVL%_LVL%[""].Remove()
          LVL%_LVL%[""].Insert(LVL%__NXT%:=Object(_KEY,(_VAL!=""||IsVal)?_VAL:LVL%_NXT%:=Object("base",base),"base",base))
        }
      } else {
        If !Yaml_SeqMap(LVL%_LVL%[""],"",_LFL)
          LVL%_LVL%[""].Insert(_LFL)
      }
      If !LVL%_LVL%[""].MaxIndex()
        LVL%_LVL%.Remove("")
    } else if (_KEY!=""){
      If (__SEQ && _LVL>__LVL) {
        If (OBJ:=LVL%_PRV%[""].MaxIndex())&&IsObject(LVL%_PRV%["",OBJ]){
          If !Yaml_SeqMap(LVL%_PRV%["",OBJ],_KEY,_VAL)
            LVL%_PRV%["",OBJ,_KEY]:=(_VAL!=""||IsVal)?_VAL:(LVL%_NXT%:=Object("base",base))
        } else {
          LVL%_PRV%[""].Insert(Object(_KEY,(_VAL!=""||IsVal)?_VAL:(LVL%_NXT%:=Object("base",base)),"base",base))
          Yaml_SeqMap(LVL%_PRV%["",OBJ?OBJ+1:1],_KEY,_VAL)
        }
      } else
        If !Yaml_SeqMap(LVL%_LVL%,_KEY,_VAL)
          LVL%_LVL%[_KEY]:=_VAL!=""?_VAL:(LVL%_NXT%:=Object("base",base))
    } else if (_LVL>__LVL && (__KEY!="")) {
      If (__VAL!="" || __SCA){
        Yaml_Continue(LVL%__LVL%,__KEY,_LFL,__SCA)
        Yaml_SeqMap(LVL%__LVL%,__KEY,LVL%__LVL%[__KEY])
        Continue
      } else {
        If !Yaml_SeqMap(LVL%__LVL%[__KEY],_KEY,_VAL) ;!!! no Scalar???
          LVL%__LVL%[__KEY,_KEY]:=_VAL
          Continue
      }
    } else {
      If (_LVL>__LVL&&(OBJ:=LVL%__LVL%[""].MaxIndex())&&IsObject(LVL%__LVL%["",OBJ])&&__SEQ){
        If __CNT
          Yaml_Continue(LVL%__LVL%[""],LVL%__LVL%[""].MaxIndex(),_LFL,__SCA,1)
        If (__CNT:=Yaml_SeqMap(LVL%__LVL%[""],"",_LFL)?"":1)
          LVL%__LVL%[""].Insert(_LFL) 
      } else {
        If !IsObject(LVL%_LVL%[""])
          LVL%_LVL%[""]:=Object("base",base)
        If __CNT
          Yaml_Continue(LVL%__LVL%[""],LVL%__LVL%[""].MaxIndex(),_LFL,__SCA,1)
        If (__CNT:=Yaml_SeqMap(LVL%_LVL%[""],"",_LFL)?"":1)
          LVL%_LVL%[""].Insert(_LFL)
      }
      Continue
    }
    Loop,Parse,BackupVars,`,
      __%A_LoopField%:=_%A_LoopField%
      ,__%A_LoopField%%_LVL%:=_%A_LoopField%
  }
  If (LastContObj && !__SCA)
      LastContObj[LastContKEY]:=SubStr(LastContObj[LastContKEY],1,-1*LinesAdded)
  AutoTrim %AutoTrim%
  Loop,Parse,BackupVars,`,
      If !(__%A_LoopField%:="")
        Loop % maxLVL
          __%A_LoopField%%A_Index%:=""
  Return pYaml,pYaml.base:=base
}
Yaml_Save(obj,file,level=""){
  FileMove,% file,% file ".bakupyml",1
  FileAppend,% obj.Dump(),% file
  If !ErrorLevel
    FileDelete,% file ".bakupyml"
  else {
    FileMove,% file ".bakupyml",% file
    MsgBox,0, Error creating file, old file was restored.
  }
}
Yaml_Call(NotSupported,f,p*){
  If (p.MaxIndex()>1){
    Loop % p.MaxIndex()
      If A_Index>1
        f:=f[""][p[A_Index-1]]
  }
  Return (!p.MaxIndex()?f[""].MaxIndex():f[""][p[p.MaxIndex()]])
}
Yaml_Merge(obj,merge){
  for k,v in merge
  {
    If IsObject(v){
      If obj.HasKey(k){
        If IsObject(obj[k])
          Yaml_Merge(obj[k],v)
        else obj[k]:=v
      } else obj[k]:=v
    } else obj[k]:=v
  }
}
Yaml_Add(O,Yaml="",IsFile=0){
  static base:={Dump:"Yaml_Dump",Save:"Yaml_Save",Add:"Yaml_Add",Merge:"Yaml_Merge",__Delete:"__Delete",_Insert:"_Insert",_Remove:"_Remove",_GetCapacity:"_GetCapacity",_SetCapacity:"_SetCapacity",_GetAddress:"_GetAddress",_MaxIndex:"_MaxIndex",_MinIndex:"_MinIndex",_NewEnum:"_NewEnum",_HasKey:"_HasKey",_Clone:"_Clone",Insert:"Insert",Remove:"Remove",GetCapacity:"GetCapacity",SetCapacity:"SetCapacity",GetAddress:"GetAddress",MaxIndex:"MaxIndex",MinIndex:"MinIndex",NewEnum:"NewEnum",HasKey:"HasKey",Clone:"Clone",base:{__Call:"Yaml_Call"}}
  If Yaml_IsSeqMap(Trim(Yaml)){
    If !IsObject(O[""])
      O[""]:=Object("base",base)
    Yaml_SeqMap(O[""],"",Yaml)
  } else Yaml(Yaml,IsFile,O)
}
Yaml_Dump(O,J="",R=0,Q=0){
  static M1:="{",M2:="}",S1:="[",S2:="]",N:="`n",C:=", ",S:="- ",E:="",K:=": "
  local dump:="",M,MX,F,I,key,value
  If (J=0&&!R)
    dump.= S1
  for key in O
    M:=A_Index
  If IsObject(O[""]){
    M--
    for key in O[""]
      MX:=A_Index
    If IsObject(O[""][""])
      MX--
    If O[""].MaxIndex()
      for key, value in O[""]
      {
        If key=
          continue
        I++
        F:=IsObject(value)?(IsObject(value[""])?"S":"M"):E
        If (J!=""&&J<=R){
          dump.=(F?(%F%1 Yaml_Dump(value,J,R+1,F) %F%2):Yaml_EscIfNeed(value)) (I=MX&&!M?E:C) ;(Q="S"&&I=1?S1:E)(Q="S"&&I=MX?S2:E)
        } else if F,dump:=dump N Yaml_I2S(R) S
          dump.= (J!=""&&J<=(R+1)?%F%1:E) Yaml_Dump(value,J,R+1,F) (J!=""&&J<=(R+1)?%F%2:E)
        else {
          ; If RegexMatch(value,"[\x{007F}-\x{FFFF}""\{\[']|:\s|\s#")
            dump .= Yaml_EscIfNeed(value)
          ; else {
            ; value:= (value=""?"''":RegExReplace(RegExReplace(Value,"m)^(.*[\r\n].*)$","|" (SubStr(value,-1)="`n`n"?"+":SubStr(value,0)=N?"":"-") "`n$1"),"ms)(*ANYCRLF)\R",N Yaml_I2S(R+1)))
            ; StringReplace,value,value,% N Yaml_I2S(R+1) N Yaml_I2S(R+1),% N Yaml_I2S(R+1),A
            ; dump.=value
          ; }
        }
      }
  }
  I=0
  for key, value in O
  {
    If key=
      continue
    I++
    F:=IsObject(value)?(IsObject(value[""])?"S":"M"):E
    If (J=0&&!R)
      dump.= M1
    If (J!=""&&J<=R){
      dump.=(Q="S"&&I=1?M1:E) Yaml_EscIfNeed(key) K
      dump.=F?(%F%1 Yaml_Dump(value,J,R+1,F) %F%2):Yaml_EscIfNeed(value)
      dump.=(Q="S"&&I=M?M2:E) (J!=0||R?(I=M?E:C):E)
    } else if F,dump:=dump N Yaml_I2S(R) Yaml_EscIfNeed(key) K
      dump.= (J!=""&&J<=(R+1)?%F%1:E) Yaml_Dump(value,J,R+1,F) (J!=""&&J<=(R+1)?%F%2:E)
    else {
      ; If RegexMatch(value,"[\x{007F}-\x{FFFF}""\{\['\t]|:\s|\s#")
        dump .= Yaml_EscIfNeed(value)
      ; else {
        ; value:= (value=""?"''":RegExReplace(RegExReplace(Value,"m)^(.*[\r\n].*)$","|" (SubStr(value,-1)="`n`n"?"+":SubStr(value,0)="`n"?"":"-") "`n$1"),"ms)(*ANYCRLF)\R","`n" Yaml_I2S(R+1)))
        ; StringReplace,value,value,% "`n" Yaml_I2S(R+1) "`n" Yaml_I2S(R+1),% "`n" Yaml_I2S(R+1),A
        ; dump.= value
      ; }
    }
    If (J=0&&!R){
      dump.=M2 (I<M?C:E)
    }
  }
  If (J=0&&!R)
    dump.=S2
  If (R=0)
    dump:=RegExReplace(dump,"^\R+")
  Return dump
}
Yaml_UniChar( string ) {
  static a:="`a",b:="`b",t:="`t",n:="`n",v:="`v",f:="`f",r:="`r",e:=Chr(0x1B)
  Loop,Parse,string,\
  {
    If (A_Index=1){
      var.=A_LoopField
      continue
    } else If lastempty {
      var.="\" A_LoopField
      lastempty:=0
      Continue
    } else if (A_LoopField=""){
      lastempty:=1
      Continue
    }
    If InStr("ux",SubStr(A_LoopField,1,1))
      str:=SubStr(A_LoopField,1,RegExMatch(A_LoopField,"^[ux]?([\dA-F]{4})?([\dA-F]{2})?\K")-1)
    else
      str:=SubStr(A_LoopField,1,1)
    If (str=="N")
      str:="\x85"
    else if (str=="P")
      str:="\x2029"
    else if (str=0)
      str:="\x0"
    else if (str=="L")
      str:="\x2028"
    else if (str=="_")
      str:="\xA0"
    If RegexMatch(str,"i)^[ux][\da-f]+$")
      var.=Chr(Abs("0x" SubStr(str,2)))
    else If str in a,b,t,n,v,f,r,e
      var.=%str%
    else var.=str
    If InStr("ux",SubStr(A_LoopField,1,1))
      var.=SubStr(A_LoopField,RegExMatch(A_LoopField,"^[ux]?([\dA-F]{4})?([\dA-F]{2})?\K"))
    else var.=SubStr(A_LoopField,2)
  }
  return var
}
Yaml_CharUni( string ) {
  static ascii:={"\":"\","`a": "a","`b": "b","`t": "t","`n": "n","`v": "v","`f": "f","`r": "r",Chr(0x1B): "e","""": """",Chr(0x85): "N",Chr(0x2029): "P",Chr(0x2028): "L","": "0",Chr(0xA0): "_"}
  If !RegexMatch(string,"[\x{007F}-\x{FFFF}]"){
    Loop,Parse,string
    {
      If ascii[A_LoopField]
        var.="\" ascii[A_LoopField]
      else
        var.=A_LoopField
    }
    return var
  }
  format:=A_FormatInteger
  SetFormat,Integer,H
  Loop,Parse,string
  {
    If ascii[A_LoopField]
        var.="\" ascii[A_LoopField]
    else if Asc(A_LoopField)<128
      var.=A_LoopField
    else {
      str:=SubStr(Asc(A_LoopField),3)	
      var.="\u" (StrLen(str)<2?"000":StrLen(str)<3?"00":StrLen(str)<4?"0":"") str
    }
  }
  SetFormat,Integer,%Format%
  return var
}
Yaml_EscIfNeed(s){
  If (s="")
    return "''"
  else If RegExMatch(s,"m)[\{\[""'\r\n]|:\s|,\s|\s#")||RegExMatch(s,"^[\s#\\\-:>]")||RegExMatch(s,"m)\s$")||RegExMatch(s,"m)[\x{7F}-\x{7FFFFFFF}]")
    return ("""" . Yaml_CharUni(s) . """")
  else return s
}
Yaml_IsQuoted(ByRef s){
	return InStr(".''."""".","." SubStr(Trim(s),1,1) SubStr(Trim(s),0) ".")?1:0
}
Yaml_UnQuoteIfNeed(s){
  s:=Trim(s)
  If !(SubStr(s,1,1)=""""&&SubStr(s,0)="""")
    return (SubStr(s,1,1)="'"&&SubStr(s,0)="'")?SubStr(s,2,StrLen(s)-2):s
  else return Yaml_UniChar(SubStr(s,2,StrLen(s)-2))
}
Yaml_S2I(str){
  local idx:=0
  Loop,Parse,str
    If (A_LoopField=A_Tab)
      idx++
    else if !Mod(A_index,2)
      idx++
  Return idx
}
Yaml_I2S(idx){
  Loop % idx
    str .= "  "
  Return str
}
Yaml_Continue(Obj,key,value,scalar="",isval=0){
  If !IsObject(isObj:=obj[key])
    v:=isObj
  If scalar {
    StringTrimLeft,scaopt,scalar,1
    scalar:=Asc(scalar)=124?"`n":" "
  } else scalar:=" ",scaopt:="-"
  temp := (value=""?"`n":(SubStr(v,0)="`n"&&scalar="`n"?"":(v=""?"":scalar))) value (scaopt!="-"?(v&&value=""?"`n":""):"")
  obj[key]:=Yaml_UnQuoteIfNeed(v temp)
}
Yaml_Quote(ByRef L,F,Q,B,ByRef E){
  Return (F="\"&&!E&&(E:=1))||(E&&!(E:=0)&&(L:=L ("\" F)))
}
Yaml_SeqMap(o,k,v,isVal=0){
  v:=Trim(v,A_Tab A_Space "`n"),m:=SubStr(v,1,1) SubStr(v,0)
  If Yaml_IsSeqMap(v)
    return m="[]"?Yaml_Seq(o,k,SubStr(v,2,StrLen(v)-2),isVal):m="{}"?Yaml_Map(o,k,SubStr(v,2,StrLen(v)-2),isVal):0
}
Yaml_Seq(obj,key,value,isVal=0){
  static base:={Dump:"Yaml_Dump",Save:"Yaml_Save",Add:"Yaml_Add",Merge:"Yaml_Merge",__Delete:"__Delete",_Insert:"_Insert",_Remove:"_Remove",_GetCapacity:"_GetCapacity",_SetCapacity:"_SetCapacity",_GetAddress:"_GetAddress",_MaxIndex:"_MaxIndex",_MinIndex:"_MinIndex",_NewEnum:"_NewEnum",_HasKey:"_HasKey",_Clone:"_Clone",Insert:"Insert",Remove:"Remove",GetCapacity:"GetCapacity",SetCapacity:"SetCapacity",GetAddress:"GetAddress",MaxIndex:"MaxIndex",MinIndex:"MinIndex",NewEnum:"NewEnum",HasKey:"HasKey",Clone:"Clone",base:{__Call:"Yaml_Call"}}
  ContinueNext:=0
  If (obj=""){
    If (SubStr(value,0)!="]")
      Return 0
    else
      value:=SubStr(value,2,StrLen(value)-2)
  } else {
    If (key=""){
      obj.Insert(Object("",cObj:=Object("base",base),"base",base))
    } else if (isval && IsObject(obj[key,""])){
        cObj:=obj[key,""]
    } else obj[key]:=Object("",cObj:=Object("base",base),"base",base)
  }
  Count:=StrLen(value)
  Loop,Parse,value
  {
    If ((Quote=""""&&Yaml_Quote(LF,A_LoopField,Quote,Bracket,Escape)) || (ContinueNext && !ContinueNext:=0))
      Continue
    If (Quote){
      If (A_LoopField=Quote){
        Quote=
        If Bracket
          LF.= A_LoopField
        else LF:=SubStr(LF,2)
        Continue
      }
      LF .= A_LoopField
      continue
    } else if (!Quote&&InStr("""'",A_LoopField)){
      Quote:=A_LoopField
      If !Bracket
        VQ:=Quote
      LF.=A_LoopField
      Continue
    } else if (!Quote&&Bracket){
      If (Asc(A_LoopField)=Asc(Bracket)+2)
        BCount--
      else if (A_LoopField=Bracket)
        BCount++
      If (BCount=0)
        Bracket=
      LF .= A_LoopField
      Continue
    } else if (!Quote&&!Bracket&&InStr("[{",A_LoopField)){
      Bracket:=A_LoopField
      BCount:=1
      LF.=A_LoopField
      Continue
    }
    If (A_Index=Count)
      LF .= A_LoopField
    else if (!Quote&&!Bracket&&A_LoopField=","&&(!InStr("0123456789",SubStr(value,A_Index-1,1)) | !InStr("0123456789",SubStr(value,A_Index+1,1)))){
      ContinueNext:=SubStr(value,A_Index+1,1)=A_Space||SubStr(value,A_Index+1,1)=A_Tab
      LF:=LF
    } else {
      LF .= A_LoopField
      continue
    }
    If (obj=""){
      If !VQ
        If (Asc(LF)=91 && !Yaml_Seq("","",LF))
          ||(Asc(LF)=123 && !Yaml_Map("","",LF))
          Return 0
    } else {
      If (VQ || !Yaml_SeqMap(cObj,"",LF))
        cObj.Insert(VQ?Yaml_UniChar(LF):Trim(LF))
    }
    LF:="",VQ:=""
  }
  If (LF){
    If (obj=""){
      If !VQ
        If (Asc(LF)=91 && !Yaml_Seq("","",LF))||(Asc(LF)=123 && !Yaml_Map("","",LF))
          Return 0
    } else If (VQ || !Yaml_SeqMap(cObj,"",LF))
      cObj.Insert(VQ?Yaml_UniChar(LF):Trim(LF))
  }
  Return (obj=""?(Quote Bracket=""):1)
}
Yaml_Map(obj,key,value,isVal=0){
  static base:={Dump:"Yaml_Dump",Save:"Yaml_Save",Add:"Yaml_Add",Merge:"Yaml_Merge",__Delete:"__Delete",_Insert:"_Insert",_Remove:"_Remove",_GetCapacity:"_GetCapacity",_SetCapacity:"_SetCapacity",_GetAddress:"_GetAddress",_MaxIndex:"_MaxIndex",_MinIndex:"_MinIndex",_NewEnum:"_NewEnum",_HasKey:"_HasKey",_Clone:"_Clone",Insert:"Insert",Remove:"Remove",GetCapacity:"GetCapacity",SetCapacity:"SetCapacity",GetAddress:"GetAddress",MaxIndex:"MaxIndex",MinIndex:"MinIndex",NewEnum:"NewEnum",HasKey:"HasKey",Clone:"Clone",base:{__Call:"Yaml_Call"}}
  ContinueNext:=0
  If (obj=""){
    If (SubStr(value,0)!="}")
      Return 0
    else
      value:=SubStr(value,2,StrLen(value)-2)
  } else {
    If (key="")
      obj.Insert(cObj:=Object("base",base))
    else obj[key]:=(cObj:=Object("base",base))
  }
  Count:=StrLen(value)
  Loop,Parse,value
  {

    If ((Quote=""""&&Yaml_Quote(LF,A_LoopField,Quote,Bracket,Escape)) || (ContinueNext && !ContinueNext:=0))
      Continue
    If (Quote){
      If (A_LoopField=Quote){
        Quote=
        LF.=A_LoopField
      } else LF .= A_LoopField
      continue
    } else if (!Quote&&(k=""||v="")&&InStr("""'",A_LoopField)){
      Quote:=A_LoopField
      If (k && !Bracket)
        VQ:=Quote
      else if !Bracket
        KQ:=Quote
      LF.=Quote
      Continue
    } else If (k!=""&&LF=""&&InStr("`n`r `t",A_LoopField)){
      Continue
    }
    If (!Quote&&Bracket){
      If (Asc(A_LoopField)=Asc(Bracket)+2)
        BCount--
      else if (A_LoopField=Bracket)
        BCount++
      If (BCount=0)
        Bracket=
      LF .= A_LoopField
      Continue
    } else if (!Quote&&!Bracket&&InStr("[{",A_LoopField)){
      Bracket:=A_LoopField
      BCount=1
      LF.=A_LoopField
      Continue
    }
    If (A_Index=Count&&k!=""){
      v:=LF A_LoopField
      v:=Trim(v)
      If (InStr("""'",SubStr(v,0))&&SubStr(v,1,1)=SubStr(v,0))
        v:=SubStr(v,2,StrLen(v)-2)
    } else If (!Quote&&!Bracket&&k!=""&&A_LoopField=","&&SubStr(value,A_Index+1,1)=A_Space){
      ContinueNext:=1
      LF:=Trim(LF)
      If VQ
        LF:=SubStr(LF,2,StrLen(LF)-2)
      v:=LF,LF:=""
    } else if (!Quote&&!Bracket&&k=""&&A_LoopField=":"){
      LF:=Trim(LF)
      If (InStr("""'",SubStr(LF,0))&&SubStr(LF,1,1)=SubStr(LF,0))
        LF:=SubStr(LF,2,StrLen(LF)-2)
      k:=LF,LF:=""
      continue
    } else {
      LF .= A_LoopField
      continue
    }
    If (obj=""){
      If VQ=
        If (Asc(v)=91 && !Yaml_Seq("","",v))
          ||(Asc(v)=123 && !Yaml_Map("","",v))
          Return 0
    } else {
      If (VQ || !Yaml_SeqMap(cObj,k,v))
        cObj[KQ?Yaml_UniChar(k):k]:=(VQ?Yaml_UniChar(v):Trim(v))
    }
    k:="",v:="",VQ:="",KQ:=""
  }
  If (k){
    If (obj=""){
      If (Asc(LF)=91 && !Yaml_Seq("","",LF))||(Asc(LF)=123 && !Yaml_Map("","",LF))
        Return 0
    } else {
      LF:=Trim(LF)
      If (VQ)
        LF:=SubStr(LF,2,StrLen(LF)-2),cObj[k]:=Yaml_UniChar(LF)
      else If (!Yaml_SeqMap(cObj,k,LF))
        cObj[k]:=Trim(LF)
    }
  }
  Return (obj=""?(Quote Bracket=""):1)
}
Yaml_Incomplete(value){
  return (Asc(Trim(value,"`n" A_Tab A_Space))=91 && !Yaml_Seq("","",Trim(value,"`n" A_Tab A_Space)))
			|| (Asc(Trim(value,"`n" A_Tab A_Space))=123 && !Yaml_Map("","",Trim(value,"`n" A_Tab A_Space)))
}
Yaml_IsSeqMap(value){
	return (Asc(Trim(value,"`n" A_Tab A_Space))=91 && Yaml_Seq("","",Trim(value,"`n" A_Tab A_Space)))
			|| (Asc(Trim(value,"`n" A_Tab A_Space))=123 && Yaml_Map("","",Trim(value,"`n" A_Tab A_Space)))
}