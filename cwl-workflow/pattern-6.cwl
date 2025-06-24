# ## 6. one input, no output

# The CWL includes: 
# - one input parameter of type `Directory`
# - there are no output parameters of type `Directory`

# This corner-case scenario takes as input an acquisition, applies an algorithm and generates an output that is not a STAC Catalog

# Implementation: derive the NDVI mean taking as input a Landsat-9 acquisition

cwlVersion: v1.0
$namespaces:
  s: https://schema.org/
s:softwareVersion: 1.0.0
schemas:
  - http://schema.org/version/9.0/schemaorg-current-http.rdf
$graph:
  - class: Workflow
    id: pattern-6
    label: NDVI mean
    doc: NDVI mean
    requirements:
      ScatterFeatureRequirement: {}
    inputs:
      aoi:
        label: area of interest
        doc: area of interest as a bounding box
        type: string
      epsg:
        label: EPSG code
        doc: EPSG code
        type: string
        default: "EPSG:4326"
      item:
        doc: Reference to a STAC item
        label: STAC item reference
        type: Directory
    outputs:
      - id: mean
        doc: Vegetation index mean
        label: Vegetation index mean
        outputSource:
          - step/mean
        type: float
    steps:
      step:
        run: "#clt"
        in:
          item: item
          aoi: aoi
          epsg: epsg
        out:
          - mean

  - class: CommandLineTool
    id: clt
    requirements:
        InlineJavascriptRequirement: {}
        EnvVarRequirement:
          envDef:
            PATH: $PATH:/app/envs/vegetation-index/bin
        ResourceRequirement:
          coresMax: 1
          ramMax: 512
    hints:
      DockerRequirement:
        dockerPull: docker.io/library/vegetation-indexes:latest
    baseCommand: 
    - vegetation-index
    arguments:
    - pattern-6
    inputs:
      item:
        type: Directory
        inputBinding:
            prefix: --input-item
      aoi:
        type: string
        inputBinding:
            prefix: --aoi
      epsg:
        type: string
        inputBinding:
            prefix: --epsg
    stdout: message
    outputs:
      mean:
        outputBinding:
          glob: message
          loadContents: true
          outputEval: $(parseFloat(self[0].contents))
        type: float

