/* Class: JSON
 *     JSON lib for AutoHotkey
 * License:
 *     WTFPL [http://wtfpl.net/]
 * Requirements:
 *     AutoHotkey v1.1.17+
 * Others:
 *     Github URL:  https://github.com/cocobelgica/AutoHotkey-JSON
 *     Email:       cocobelgica@gmail.com
 *     Last Update: 02/15/2015 (MM/DD/YYYY)
 */
class JSON
{
	/* Method: parse
	 *     Deserialize a string containing a JSON document to an AHK object.
	 * Syntax:
	 *     json_obj := JSON.parse( ByRef src [ , jsonize := false ] )
	 * Parameter(s):
	 *     src  [in, ByRef] - String containing a JSON document
	 *     jsonize     [in] - If true, objects {} and arrays [] are wrapped as
	 *                        JSON.object and JSON.array instances respectively.
	 */
	parse(ByRef src, jsonize:=false)
	{
		args := jsonize ? [ JSON.object, JSON.array ] : []
		key := "", is_key := false
		stack := [ tree := [] ]
		is_arr := { (tree): 1 }
		next := """{[01234567890-tfn"
		pos := 0
		while ( (ch := SubStr(src, ++pos, 1)) != "" )
		{
			if InStr(" `t`n`r", ch)
				continue
			if !InStr(next, ch)
			{
				ln  := ObjMaxIndex(StrSplit(SubStr(src, 1, pos), "`n"))
				col := pos - InStr(src, "`n",, -(StrLen(src)-pos+1))

				msg := Format("{}: line {} col {} (char {})"
				,   (next == "")    ? ["Extra data", ch := SubStr(src, pos)][1]
				  : (next == "'")   ? "Unterminated string starting at"
				  : (next == "\")   ? "Invalid \escape"
				  : (next == ":")   ? "Expecting ':' delimiter"
				  : (next == """")  ? "Expecting object key enclosed in double quotes"
				  : (next == """}") ? "Expecting object key enclosed in double quotes or object closing '}'"
				  : (next == ",}")  ? "Expecting ',' delimiter or object closing '}'"
				  : (next == ",]")  ? "Expecting ',' delimiter or array closing ']'"
				  : [ "Expecting JSON value(string, number, [true, false, null], object or array)"
				    , ch := SubStr(src, pos, (SubStr(src, pos)~="[\]\},\s]|$")-1) ][1]
				, ln, col, pos)

				throw Exception(msg, -1, ch)
			}
			
			is_array := is_arr[obj := stack[1]]
			
			if i := InStr("{[", ch)
			{
				val := (proto := args[i]) ? new proto : {}
				is_array? ObjInsert(obj, val) : obj[key] := val
				ObjInsert(stack, 1, val)
				
				is_arr[val] := !(is_key := ch == "{")
				next := is_key ? """}" : """{[]0123456789-tfn"
			}

			else if InStr("}]", ch)
			{
				ObjRemove(stack, 1)
				next := stack[1]==tree ? "" : is_arr[stack[1]] ? ",]" : ",}"
			}

			else if InStr(",:", ch)
			{
				is_key := (!is_array && ch == ",")
				next := is_key ? """" : """{[0123456789-tfn"
			}

			else
			{
				if (ch == """")
				{
					i := pos
					while (i := InStr(src, """",, i+1))
					{
						val := SubStr(src, pos+1, i-pos-1)
						StringReplace, val, val, \\, \u005C, A
						if (SubStr(val, 0) != "\")
							break
					}
					if !i ? (pos--, next := "'") : 0
						continue
					
					pos := i

					StringReplace, val, val, \/,  /, A
					StringReplace, val, val, \",  ", A
					StringReplace, val, val, \b, `b, A
					StringReplace, val, val, \f, `f, A
					StringReplace, val, val, \n, `n, A
					StringReplace, val, val, \r, `r, A
					StringReplace, val, val, \t, `t, A

					i := 0
					while (i := InStr(val, "\",, i+1))
					{
						if (SubStr(val, i+1, 1) != "u") ? (pos -= StrLen(SubStr(val, i)), next := "\") : 0
							continue 2

						; \uXXXX - JSON unicode escape sequence
						xxxx := Abs("0x" . SubStr(val, i+2, 4))
						if (A_IsUnicode || xxxx < 0x100)
							val := SubStr(val, 1, i-1) . Chr(xxxx) . SubStr(val, i+6)
					}

					if is_key
					{
						key := val, next := ":"
						continue
					}
				}
				
				else
				{
					val := SubStr(src, pos, i := RegExMatch(src, "[\]\},\s]|$",, pos)-pos)
					
					static null := "" ; for #Warn
					if InStr(",true,false,null,", "," . val . ",", true) ; if var in
						val := %val%
					else if (Abs(val) == "") ? (pos--, next := "#") : 0
						continue
					
					val := val + 0, pos += i-1
				}
				
				is_array? ObjInsert(obj, val) : obj[key] := val
				next := obj==tree ? "" : is_array ? ",]" : ",}"
			}
		}
		
		return tree[1]
	}
	/* Method: stringify
	 *     Serialize an object to a JSON formatted string.
	 * Syntax:
	 *     json_str := JSON.stringify( obj [ , indent := "" ] )
	 * Parameter(s):
	 *     obj      [in] - The object to stringify.
	 *     indent   [in] - Specify string(s) to use as indentation per level.
 	 */
	stringify(obj:="", indent:="", lvl:=1)
	{
		if IsObject(obj)
		{
			if (ObjGetCapacity(obj) == "") ; COM,Func,RegExMatch,File,Property object
				throw Exception("Object type not supported.", -1, Format("<Object at 0x{:p}>", &obj))
			
			is_array := 0
			for k in obj
				is_array := (k == A_Index)
			until !is_array

			if indent is integer
			{
				if (indent < 0)
					throw Exception("Indent parameter must be a postive integer.", -1, indent)
				spaces := indent, indent := ""
				Loop % spaces
					indent .= " "
			}
			indt := ""
			Loop, % indent ? lvl : 0
				indt .= indent

			lvl += 1, out := "" ; make #Warn happy
			for k, v in obj
			{
				if IsObject(k) || (k == "")
					throw Exception("Invalid object key.", -1, k ? Format("<Object at 0x{:p}>", &obj) : "<blank>")
				
				if !is_array
					out .= ( ObjGetCapacity([k], 1) ? JSON.stringify(k) : """" . k . """" ) ; key
					    .  ( indent ? ": " : ":" ) ; token + padding
				out .= JSON.stringify(v, indent, lvl) ; value
				    .  ( indent ? ",`n" . indt : "," ) ; token + indent
			}
			
			if (out != "")
			{
				out := Trim(out, ",`n" indent)
				if (indent != "")
					out := Format("`n{}{}`n{}", indt, out, SubStr(indt, StrLen(indent)+1))
			}
			
			return is_array ? "[" . out . "]" : "{" . out . "}"
		}
		
		; Number
		if (ObjGetCapacity([obj], 1) == "") ; returns an integer if 'obj' is string
			return obj
		
		; String (null -> not supported by AHK)
		if (obj != "")
		{
			StringReplace, obj, obj,  \, \\, A
			StringReplace, obj, obj,  /, \/, A
			StringReplace, obj, obj,  ", \", A
			StringReplace, obj, obj, `b, \b, A
			StringReplace, obj, obj, `f, \f, A
			StringReplace, obj, obj, `n, \n, A
			StringReplace, obj, obj, `r, \r, A
			StringReplace, obj, obj, `t, \t, A

			while RegExMatch(obj, "[^\x20-\x7e]", m)
				StringReplace, obj, obj, %m%, % Format("\u{:04X}", Asc(m)), A
		}
		
		return """" . obj . """"
	}
	
	class object
	{
		
		__New(args*)
		{
			ObjInsert(this, "_", [])
			if ((count := NumGet(&args+4*A_PtrSize)) & 1)
				throw "Invalid number of parameters"
			Loop % count//2
				this[args[A_Index*2-1]] := args[A_Index*2]
		}

		__Set(key, val, args*)
		{
			ObjInsert(this._, key)
		}

		Insert(key, val)
		{
			return this[key] := val
		}
		/* Buggy - remaining integer keys are not adjusted
		Remove(args*) { 
			ret := ObjRemove(this, args*), i := -1
			for index, key in ObjClone(this._) {
				if ObjHasKey(this, key)
					continue
				ObjRemove(this._, index-(i+=1))
			}
			return ret
		}
		*/
		Count()
		{
			return NumGet(&(this._) + 4*A_PtrSize) ; Round(this._.MaxIndex())
		}

		stringify(indent:="")
		{
			return JSON.stringify(this, indent)
		}

		_NewEnum()
		{
			static proto := { "Next": JSON.object.Next }
			return { base: proto, enum: this._._NewEnum(), obj: this }
		}

		Next(ByRef key, ByRef val:="")
		{
			if (ret := this.enum.Next(i, key))
				val := this.obj[key]
			return ret
		}
	}
		
	class array
	{
			
		__New(args*)
		{
			args.base := this.base
			return args
		}

		stringify(indent:="")
		{
			return JSON.stringify(this, indent)
		}
	}
}