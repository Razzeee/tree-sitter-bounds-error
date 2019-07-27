module Array
    exposing
        ( Array
        , empty
        , isEmpty
        , length
        , initialize
        , repeat
        , fromList
        , get
        , set
        , push
        , toList
        , toIndexedList
        , foldr
        , foldl
        , filter
        , map
        , indexedMap
        , append
        , slice
        )


initialize : Int -> (Int -> a) -> Array a
initialize len fn =
    if len <= 0 then
        empty
    else
        let
            tailLen =
                remainderBy branchFactor len

            tail =
                JsArray.initialize tailLen (len - tailLen) fn

            initialFromIndex =
                len - tailLen - branchFactor
        in
            initializeHelp fn initialFromIndex len [] tail


initializeHelp : (Int -> a) -> Int -> Int -> List (Node a) -> JsArray a -> Array a
initializeHelp fn fromIndex len nodeList tail =
    if fromIndex < 0 then
        builderToArray False
            { tail = tail
            , nodeList = nodeList
            , nodeListSize = len // branchFactor
            }
    else
        let
            leaf =
                Leaf <| JsArray.initialize branchFactor fromIndex fn
        in
            initializeHelp
                fn
                (fromIndex - branchFactor)
                len
                (leaf :: nodeList)
                tail


repeat : Int -> a -> Array a
repeat n e =
    initialize n (\_ -> e)


fromList : List a -> Array a
fromList list =
    case list of
        [] ->
            empty

        _ ->
            fromListHelp list [] 0


fromListHelp : List a -> List (Node a) -> Int -> Array a
fromListHelp list nodeList nodeListSize =
    let
        ( jsArray, remainingItems ) =
            JsArray.initializeFromList branchFactor list
    in
        if JsArray.length jsArray < branchFactor then
            builderToArray True
                { tail = jsArray
                , nodeList = nodeList
                , nodeListSize = nodeListSize
                }
        else
            fromListHelp
                remainingItems
                (Leaf jsArray :: nodeList)
                (nodeListSize + 1)


{--}
get : Int -> Array a -> Maybe a
get index (Array_elm_builtin len startShift tree tail) =
    if index < 0 || index >= len then
        Nothing
    else if index >= tailIndex len then
        Just <| JsArray.unsafeGet (Bitwise.and bitMask index) tail
    else
        Just <| getHelp startShift index tree


getHelp : Int -> Int -> Tree a -> a
getHelp shift index tree =
    let
        pos =
            Bitwise.and bitMask <| Bitwise.shiftRightZfBy shift index
    in
        case JsArray.unsafeGet pos tree of
            SubTree subTree ->
                getHelp (shift - shiftStep) index subTree

            Leaf values ->
                JsArray.unsafeGet (Bitwise.and bitMask index) values


{--}
tailIndex : Int -> Int
tailIndex len =
    len
        |> Bitwise.shiftRightZfBy 5
        |> Bitwise.shiftLeftBy 5


{--}
set : Int -> a -> Array a -> Array a
set index value ((Array_elm_builtin len startShift tree tail) as array) =
    if index < 0 || index >= len then
        array
    else if index >= tailIndex len then
        Array_elm_builtin len startShift tree <|
            JsArray.unsafeSet (Bitwise.and bitMask index) value tail
    else
        Array_elm_builtin
            len
            startShift
            (setHelp startShift index value tree)
            tail


setHelp : Int -> Int -> a -> Tree a -> Tree a
setHelp shift index value tree =
    let
        pos =
            Bitwise.and bitMask <| Bitwise.shiftRightZfBy shift index
    in
        case JsArray.unsafeGet pos tree of
            SubTree subTree ->
                let
                    newSub =
                        setHelp (shift - shiftStep) index value subTree
                in
                    JsArray.unsafeSet pos (SubTree newSub) tree

            Leaf values ->
                let
                    newLeaf =
                        JsArray.unsafeSet (Bitwise.and bitMask index) value values
                in
                    JsArray.unsafeSet pos (Leaf newLeaf) tree


{--}
push : a -> Array a -> Array a
push a ((Array_elm_builtin _ _ _ tail) as array) =
    unsafeReplaceTail (JsArray.push a tail) array


{--}
unsafeReplaceTail : JsArray a -> Array a -> Array a
unsafeReplaceTail newTail (Array_elm_builtin len startShift tree tail) =
    let
        originalTailLen =
            JsArray.length tail

        newTailLen =
            JsArray.length newTail

        newArrayLen =
            len + (newTailLen - originalTailLen)
    in
        if newTailLen == branchFactor then
            let
                overflow =
                    Bitwise.shiftRightZfBy shiftStep newArrayLen > Bitwise.shiftLeftBy startShift 1
            in
                if overflow then
                    let
                        newShift =
                            startShift + shiftStep

                        newTree =
                            JsArray.singleton (SubTree tree)
                                |> insertTailInTree newShift len newTail
                    in
                        Array_elm_builtin
                            newArrayLen
                            newShift
                            newTree
                            JsArray.empty
                else
                    Array_elm_builtin
                        newArrayLen
                        startShift
                        (insertTailInTree startShift len newTail tree)
                        JsArray.empty
        else
            Array_elm_builtin
                newArrayLen
                startShift
                tree
                newTail


insertTailInTree : Int -> Int -> JsArray a -> Tree a -> Tree a
insertTailInTree shift index tail tree =
    let
        pos =
            Bitwise.and bitMask <| Bitwise.shiftRightZfBy shift index
    in
        if pos >= JsArray.length tree then
            if shift == 5 then
                JsArray.push (Leaf tail) tree
            else
                let
                    newSub =
                        JsArray.empty
                            |> insertTailInTree (shift - shiftStep) index tail
                            |> SubTree
                in
                    JsArray.push newSub tree
        else
            let
                value =
                    JsArray.unsafeGet pos tree
            in
                case value of
                    SubTree subTree ->
                        let
                            newSub =
                                subTree
                                    |> insertTailInTree (shift - shiftStep) index tail
                                    |> SubTree
                        in
                            JsArray.unsafeSet pos newSub tree

                    Leaf _ ->
                        let
                            newSub =
                                JsArray.singleton value
                                    |> insertTailInTree (shift - shiftStep) index tail
                                    |> SubTree
                        in
                            JsArray.unsafeSet pos newSub tree



{--}
toIndexedList : Array a -> List ( Int, a )
toIndexedList ((Array_elm_builtin len _ _ _) as array) =
    let
        helper entry ( index, list ) =
            ( index - 1, (index,entry) :: list )
    in
        Tuple.second (foldr helper ( len - 1, [] ) array)


{--}
sliceTree : Int -> Int -> Tree a -> Tree a
sliceTree shift endIdx tree =
    let
        lastPos =
            Bitwise.and bitMask <| Bitwise.shiftRightZfBy shift endIdx
    in
        case JsArray.unsafeGet lastPos tree of
            SubTree sub ->
                let
                    newSub =
                        sliceTree (shift - shiftStep) endIdx sub
                in
                    if JsArray.length newSub == 0 then
                        JsArray.slice 0 lastPos tree
                    else
                        tree
                            |> JsArray.slice 0 (lastPos + 1)
                            |> JsArray.unsafeSet lastPos (SubTree newSub)

            -- This is supposed to be the new tail. Fetched by `fetchNewTail`.
            -- Slice up to, but not including, this point.
            Leaf _ ->
                JsArray.slice 0 lastPos tree


{--}
hoistTree : Int -> Int -> Tree a -> Tree a
hoistTree oldShift newShift tree =
    if oldShift <= newShift || JsArray.length tree == 0 then
        tree
    else
        case JsArray.unsafeGet 0 tree of
            SubTree sub ->
                hoistTree (oldShift - shiftStep) newShift sub

            Leaf _ ->
                tree


{--}
sliceLeft : Int -> Array a -> Array a
sliceLeft from ((Array_elm_builtin len _ tree tail) as array) =
    if from == 0 then
        array
    else if from >= tailIndex len then
        Array_elm_builtin (len - from) shiftStep JsArray.empty <|
            JsArray.slice (from - tailIndex len) (JsArray.length tail) tail
    else
        let
            helper node acc =
                case node of
                    SubTree subTree ->
                        JsArray.foldr helper acc subTree

                    Leaf leaf ->
                        leaf :: acc

            leafNodes =
                JsArray.foldr helper [ tail ] tree

            skipNodes =
                from // branchFactor

            nodesToInsert =
                List.drop skipNodes leafNodes
        in
            case nodesToInsert of
                [] ->
                    empty

                head :: rest ->
                    let
                        firstSlice =
                            from - (skipNodes * branchFactor)

                        initialBuilder =
                            { tail =
                                JsArray.slice
                                    firstSlice
                                    (JsArray.length head)
                                    head
                            , nodeList = []
                            , nodeListSize = 0
                            }
                    in
                        List.foldl appendHelpBuilder initialBuilder rest
                            |> builderToArray True


{--}
type alias Builder a =
    { tail : JsArray a
    , nodeList : List (Node a)
    , nodeListSize : Int
    }


{--}
emptyBuilder : Builder a
emptyBuilder =
    { tail = JsArray.empty
    , nodeList = []
    , nodeListSize = 0
    }


builderToArray : Bool -> Builder a -> Array a
builderToArray reverseNodeList builder =
    if builder.nodeListSize == 0 then
        Array_elm_builtin
            (JsArray.length builder.tail)
            shiftStep
            JsArray.empty
            builder.tail
    else
        let
            treeLen =
                builder.nodeListSize * branchFactor

            depth =
                (treeLen - 1)
                    |> toFloat
                    |> logBase (toFloat branchFactor)
                    |> floor

            correctNodeList =
                if reverseNodeList then
                    List.reverse builder.nodeList
                else
                    builder.nodeList

            tree =
                treeFromBuilder correctNodeList builder.nodeListSize
        in
            Array_elm_builtin
                (JsArray.length builder.tail + treeLen)
                (max 5 <| depth * shiftStep)
                tree
                builder.tail


{--}
treeFromBuilder : List (Node a) -> Int -> Tree a
treeFromBuilder nodeList nodeListSize =
    let
        newNodeSize =
            ((toFloat nodeListSize) / (toFloat branchFactor))
                |> ceiling
    in
        if newNodeSize == 1 then
            JsArray.initializeFromList branchFactor nodeList
                |> Tuple.first
        else
            treeFromBuilder
                (compressNodes nodeList [])
                newNodeSize


{--}
compressNodes : List (Node a) -> List (Node a) -> List (Node a)
compressNodes nodes acc =
    let
        ( node, remainingNodes ) =
            JsArray.initializeFromList branchFactor nodes

        newAcc =
            (SubTree node) :: acc
    in
        case remainingNodes of
            [] ->
                List.reverse newAcc

            _ ->
                compressNodes remainingNodes newAcc
