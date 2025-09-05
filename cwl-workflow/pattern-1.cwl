cwlVersion: v1.0
$namespaces:
  s: https://schema.org/

schemas:
  - http://schema.org/version/9.0/schemaorg-current-http.rdf

s:softwareVersion: 1.0.0

s:applicationCategory: "Earth Observation application package"
s:additionalProperty:
  - s:@type: s:PropertyValue
    s:name: application-type
    s:value: delineation
  - s:@type: s:PropertyValue
    s:name: domain
    s:value: hydrology

s:thumbnail: 
  s:@type: s:ImageObject
  s:contentUrl: "https://s3.waw3-2.cloudferro.com/swift/v1/stac-png/S2_L2A.jpg"
  s:caption: "Water bodies detected based on the NDWI and otsu threshold"
  s:encodingFormat: "image/jpeg"
  s:height: "360"
  s:width: "640"


s:license:
  s:@type: s:CreativeWork
  s:name: "License CC BY 4.0"
  s:url: "https://creativecommons.org/licenses/by/4.0/"
  s:encodingFormat: "text/html"

s:documentation:
  - s:@type: s:CreativeWork
    s:name: "User Manual"
    s:url: "https://eoap.github.io/application-package-patterns/"
    s:encodingFormat: "text/html"

s:author:
  s:@type: s:Person
  s:name: "John Doe"
  s:affiliation:
    s:@type: s:Organization
    s:name: "Make EO Great Again Platform"
  s:email: "john.doe@meogap.org"
  
$graph:
  - class: Workflow
    id: pattern-1
    label: Water bodies detection based on NDWI and the otsu threshold
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
        label: Water bodies detection
        doc: Water bodies detection based on NDWI and otsu threshold applied to a single Landsat-8/9 acquisition
        in:
          item: item
          aoi: aoi
          epsg: epsg
          band: bands
        out:
          - stac-catalog
  - class: CommandLineTool
    id: clt
    requirements:
        InlineJavascriptRequirement: {}
        EnvVarRequirement:
          envDef:
            PATH: /app/envs/runner/bin
        ResourceRequirement:
          coresMax: 1
          ramMax: 512
    hints:
      DockerRequirement:
        dockerPull: ghcr.io/eoap/application-package-patterns/runner:0.2.0
    baseCommand: 
    - runner
    arguments:
    - pattern-1
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


