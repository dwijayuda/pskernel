import Ps.BackendTs.Type
import Init.Data.String.Defs
import Init.Data.ByteArray.Bootstrap

/- R6 decision experiment. No theorem about the still-legacy psTsJoin is assumed. -/
namespace Ps.MinKernel.TextComposition

def utf8 (text : String) : List UInt8 := text.toByteArray.data.toList

theorem append_utf8 (left right : String) :
    utf8 (String.append left right) = utf8 left ++ utf8 right := rfl

theorem empty_utf8 : utf8 "" = [] := rfl

end Ps.MinKernel.TextComposition
