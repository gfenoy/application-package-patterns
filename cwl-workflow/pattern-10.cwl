# ## 10. multiple inputs, multiple outputs

# The CWL includes: 
# - input parameter of type `Directory[]`
# - output parameter of type `Directory[]`

# This scenario takes as input an array of acquisition, applies an algorithm to each of them. 


cwlVersion: v1.0
$namespaces:
  s: https://schema.org/
s:softwareVersion: 1.0.0
schemas:
  - http://schema.org/version/9.0/schemaorg-current-http.rdf
$graph:
  - class: Workflow
    id: main
    label: NDVI and NDWI vegetation indexes
    doc: NDVI and NDWI vegetation indexes
    requirements:
      SubworkflowFeatureRequirement: {}
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
      indexes:
        label: indexes
        doc: indexes to compute
        type: string[]
        default: ["ndvi", "ndwi"]
      item:
        doc: Reference to a STAC item
        label: STAC item reference
        type: Directory[]

    outputs:
      - id: vegetation_indexes
        doc: Vegetation indexes
        label: Vegetation indexes
        outputSource:
          - subworkflow/vegetation_indexes
        
        type:
          type: array
          items:
            type: array
            items: Directory

    steps:
      subworkflow:
        run: "#vegetation_indexes"
        in:
          item: item
          aoi: aoi
          epsg: epsg
          indexes: indexes
        out:
          - vegetation_indexes
        scatter: 
        - item
        scatterMethod: dotproduct


  - class: Workflow
    id: vegetation_indexes
    label: NDVI and NDWI vegetation indexes
    doc: NDVI and NDWI vegetation indexes
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
      indexes:
        label: indexes
        doc: indexes to compute
        type: string[]
        default: ["ndvi", "ndwi"]
      item:
        doc: Reference to a STAC item
        label: STAC item reference
        type: Directory
    outputs:
      - id: vegetation_indexes
        doc: Vegetation indexes
        label: Vegetation indexes
        outputSource:
          - step/vegetation_index
        type: Directory[]
    steps:
      step:
        run: "#clt"
        in:
          item: item
          aoi: aoi
          epsg: epsg
          index: indexes
        out:
          - vegetation_index
        scatter: index
        scatterMethod: dotproduct

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
    - pattern-5
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

      index:
        type: string
        inputBinding:
            prefix: --vegetation-index

    outputs:
      vegetation_index:
        outputBinding:
            glob: . 
        type: Directory


