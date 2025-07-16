cwlVersion: v1.0
$namespaces:
  s: https://schema.org/
s:softwareVersion: 1.0.0
s:applicationCategory: "Earth Observation application package"
s:additionalProperty:
  - s:@type: s:PropertyValue
    s:name: application-type
    s:value: vegetation-index
  - s:@type: s:PropertyValue
    s:name: domain
    s:value: agriculture
schemas:
  - http://schema.org/version/9.0/schemaorg-current-http.rdf
$graph:
  - class: Workflow
    id: pattern-4
    label: NDVI and NDWI vegetation indexes
    doc: NDVI and NDWI vegetation indexes from Landsat-8/9 acquisitions
    requirements: []
    inputs:
      aoi:
        label: area of interest
        doc: area of interest as a bounding box
        type: string
        default: "-118.985,38.432,-118.183,38.938"
      epsg:
        label: EPSG code
        doc: EPSG code
        type: string
        default: "EPSG:4326"
      item:
        doc: Landsat-8/9 acquisition reference
        label: Landsat-8/9 acquisition reference
        type: Directory
    outputs:
      - id: ndvi
        doc: NDVI vegetation index
        label: NDVI vegetation index
        outputSource:
          - step/ndvi
        type: Directory
      - id: ndwi
        doc: NDWI vegetation index
        label: NDWI vegetation index
        outputSource:
          - step/ndwi
        type: Directory
    steps:
      step:
        run: "#clt"
        in:
          item: item
          aoi: aoi
          epsg: epsg
        out:
          - ndvi
          - ndwi
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
    - pattern-4
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
    outputs:
      ndvi:
        outputBinding:
            glob: ndvi 
        type: Directory
      ndwi:
        outputBinding:
            glob: ndwi
        type: Directory

