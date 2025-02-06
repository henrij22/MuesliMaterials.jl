module MuesliMaterials

using CxxWrap
using MuesliMaterialsWrapper_jll

@wrapmodule(() -> libjlmuesli)

function __init__()
    @initcxx
end

end
