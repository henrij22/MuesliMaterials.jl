using Documenter, DocumenterCodeBlocks, MuesliMaterials

const liveserver = "liveserver" in ARGS

if liveserver
    using Revise
    Revise.revise()
end

DocMeta.setdocmeta!(MuesliMaterials, :DocTestSetup, :(using MuesliMaterials); recursive = true)

makedocs(;
    format = Documenter.HTML(;
        canonical = "https://henrij22.github.io/MuesliMaterials.jl/stable",
        collapselevel = 1
    ),
    repo = Documenter.Remotes.GitHub("henrij22", "MuesliMaterials.jl"),
    plugins = [CodeBlocks()],
    modules = [MuesliMaterials],
    sitename = "MuesliMaterials.jl",
    warnonly = true, checkdocs = :none,
    pages = [
        "Home" => "index.md",
        "Examples" => [
            "Examples overview" => "02_examples/00_index.md",
            "02_examples/01_tensors.md",
            "02_examples/02_smallstrain.md",
            "02_examples/03_finitestrain.md"
        ],
        "API Reference" => [
            "Reference overview" => "01_api_reference/00_index.md",
            "01_api_reference/01_tensors.md",
            "01_api_reference/02_materials.md",
            "01_api_reference/03_materialpoints.md"
        ]
    ]
)

if !liveserver
    deploydocs(;
        repo = "github.com/henrij22/MuesliMaterials.jl.git",
        push_preview = true,
        versions = [
            "stable" => "v^",
            "dev" => "dev"
        ]
    )
end
