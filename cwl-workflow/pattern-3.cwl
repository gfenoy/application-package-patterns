cwlVersion: v1.0
$namespaces:
  s: https://schema.org/
s:softwareVersion: 1.0.0
schemas:
  - http://schema.org/version/9.0/schemaorg-current-http.rdf
$graph:
  - class: Workflow
    id: pattern-3
    label: Water bodies detection based on NDWI and the otsu threshold
    doc: Water bodies detection based on NDWI and otsu threshold applied to a single Sentinel-2 COG STAC item
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
      bands:
        label: bands used for the NDWI
        doc: bands used for the NDWI
        type: string[]
        default: ["green", "nir08"]
      items:
        doc: Reference to a STAC item
        label: STAC item reference
        type: Directory[]
    outputs:
      - id: stac_catalog
        outputSource:
          - step/stac-catalog
        type: Directory[]
    steps:
      step:
        run: "#clt"
        in:
          item: items
          aoi: aoi
          epsg: epsg
          band: bands
        out:
          - stac-catalog
        scatter: item
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
    - pattern-3
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
      band:
        type:
          - type: array
            items: string
            inputBinding:
              prefix: '--band'

    outputs:
      stac-catalog:
        outputBinding:
            glob: .
        type: Directory


