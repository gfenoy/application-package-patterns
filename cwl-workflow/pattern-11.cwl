cwlVersion: v1.0
$namespaces:
  s: https://schema.org/
s:softwareVersion: 1.0.0
s:applicationCategory: "Earth Observation application package"
s:additionalProperty:
  - s:@type: s:PropertyValue
    s:name: application-type
    s:value: delineation
  - s:@type: s:PropertyValue
    s:name: domain
    s:value: hydrology
schemas:
  - http://schema.org/version/9.0/schemaorg-current-http.rdf
$graph:
  - class: Workflow
    id: pattern-11
    label: Water bodies detection based on NDWI and the otsu threshold (with DEM)
    doc: Water bodies detection based on NDWI and otsu threshold applied to a single Landsat-8/9 acquisition
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
      bands:
        label: bands used for the NDWI
        doc: bands used for the NDWI
        type: string[]
        default: ["green", "nir08"]
      item:
        doc: Landsat-8/9 acquisition reference
        label: Landsat-8/9 acquisition reference
        type: Directory
      dem: 
        doc: Digital Elevation Model (DEM) geotiff
        label: Digital Elevation Model (DEM)
        type: File
    outputs:
      - id: water_bodies
        label: Water bodies detected
        doc: Water bodies detected based on the NDWI and otsu threshold
        outputSource:
          - step/stac-catalog
        type: Directory
    steps:
      step:
        run: "#clt"
        in:
          item: item
          aoi: aoi
          epsg: epsg
          band: bands
          dem: dem
        out:
          - stac-catalog
  - class: CommandLineTool
    id: clt
    requirements:
        InlineJavascriptRequirement: {}
        EnvVarRequirement:
          envDef:
            PATH: $PATH:/app/envs/runner/bin
        ResourceRequirement:
          coresMax: 1
          ramMax: 512
    hints:
      DockerRequirement:
        dockerPull: docker.io/library/runner:latest
    baseCommand:
    - runner
    arguments:
    - pattern-11
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
      dem: 
        type: File
        inputBinding:
            prefix: --dem
    outputs:
      stac-catalog:
        outputBinding:
            glob: .
        type: Directory


