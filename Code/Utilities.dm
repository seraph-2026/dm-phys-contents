
proc
    phys_splitX(stringOrNum)
    
        if(isnum(stringOrNum)) 
            return vector(text2num(stringOrNum), text2num(stringOrNum))

        else if(istext(stringOrNum))
            var/list/splitString = splittext(stringOrNum, "x")
            
            if(splitString.len == 0)
                throw EXCEPTION("id3_SplitX failed because it found no x or no numbers. Value was: [stringOrNum]")

            else if(splitString.len == 1)
                throw EXCEPTION("id3_SplitX failed because it found only one number. Value was: [stringOrNum]")

            else if(splitString.len == 2)
                return vector(text2num(splitString["0"]), text2num(splitString["1"]))
            
            else
                throw EXCEPTION("id3_SplitX failed because it found more than two numbers. Value was: [stringOrNum]")
        else
            throw EXCEPTION("id3_SplitX failed because parameter was not a string or number")