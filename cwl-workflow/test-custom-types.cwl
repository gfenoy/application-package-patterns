cwlVersion: v1.2
$namespaces:
  s: https://schema.org/

schemas:
  - http://schema.org/version/9.0/schemaorg-current-http.rdf

s:softwareVersion: 1.0.0

$graph:
  - id: test-custom-types
    class: Workflow
    label: Echo custom CWL Types
    doc: This workflow demonstrates usage of all CWL primitive types. It runs the `echo-tool` with default values and captures the output in a file.
    requirements:
    - class: InlineJavascriptRequirement
    - class: SchemaDefRequirement
      types:
      - $import: https://raw.githubusercontent.com/eoap/schemas/main/ogc.yaml
      - $import: https://raw.githubusercontent.com/eoap/schemas/main/geojson.yaml
      - $import: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml
    inputs:
    - id: bbox
      type: https://raw.githubusercontent.com/eoap/schemas/main/ogc.yaml#BBox
      label: "Area of interest"
      doc: "Area of interest defined as a bounding box"
    
    - id: point_of_interest
      type: https://raw.githubusercontent.com/eoap/schemas/main/geojson.yaml#Point
      label: "Point of Interest"
      doc: "Point of interest defined in GeoJSON format"

    - id: aoi
      type: https://raw.githubusercontent.com/eoap/schemas/main/geojson.yaml#Feature
      label: "Area of interest"
      doc: "Area of interest defined in GeoJSON format"

    - id: start_time
      type: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#DateTime
      label: "Start Time"
      doc: "Start time in ISO 8601 format"

    - id: product_uri
      type: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URI
      label: "Product URI"
      doc: "Product URI in string format"

    outputs:
      - id: echoed_values
        type: string
        outputSource: 
        - echo_step/echoed
        label: Echoed Values
        doc: The string containing echoed values

    steps:
      echo_step:
        run: "#clt"
        in:
          bbox: bbox
          point_of_interest: point_of_interest
          aoi: aoi
          start_time: start_time
          product_uri: product_uri
        out:
        - echoed

  - class: CommandLineTool
    label: Echo Tool
    doc: A tool that echoes the inputs.
    id: clt

    requirements:
      InlineJavascriptRequirement: {}
      EnvVarRequirement:
        envDef:
          PATH: $PATH:/app/envs/vegetation-index/bin:/usr/bin
      ResourceRequirement:
        coresMax: 1
        ramMax: 256
    
      DockerRequirement:
        dockerPull: ghcr.io/eoap/application-package-patterns/vegetation-indexes@sha256:db75818d12e3ea05b583ff53e32cd291fc3d40a62ae8cb53d51573c56813f1b6
      SchemaDefRequirement:
        types:
          - $import: https://raw.githubusercontent.com/eoap/schemas/main/ogc.yaml
          - $import: https://raw.githubusercontent.com/eoap/schemas/main/geojson.yaml
          - $import: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml
    baseCommand: 
    - echo
    arguments:
      - $(inputs.bbox)
      - $(inputs.point_of_interest)
      - $(inputs.aoi)
      - $(inputs.start_time)
      - $(inputs.product_uri)

    inputs:
      bbox:
        type: https://raw.githubusercontent.com/eoap/schemas/main/ogc.yaml#BBox
        label: "Area of interest"
        doc: "Area of interest defined as a bounding box"
        inputBinding:
          position: 1
          valueFrom: |
            ${
              // Validate the length of bbox to be either 4 or 6
              var bboxLength = inputs.bbox.bbox.length;
              if (bboxLength !== 4 && bboxLength !== 6) {
                throw "Invalid bbox length: bbox must have either 4 or 6 elements.";
              }
              // Convert bbox array to a space-separated string for echo
              return "Bbox: " + inputs.bbox.bbox.join(" ") + " CRS: " + inputs.bbox.crs;
            }
        
      
      point_of_interest:
        type: https://raw.githubusercontent.com/eoap/schemas/main/geojson.yaml#Point
        label: "Point of Interest"
        doc: "Point of interest defined in GeoJSON format"
        inputBinding:
          position: 2
          valueFrom: |
            ${
              // Validate if type is Point
              if (inputs.point_of_interest.type !== "Point") {
                throw "Invalid GeoJSON type: expected \"Point\", got \"" + inputs.point_of_interest.type + "\"";
              }
              var coordinates = inputs.point_of_interest.coordinates;
              return "Point Coordinates: " + coordinates.join(", ");
            }
      aoi:
        type: https://raw.githubusercontent.com/eoap/schemas/main/geojson.yaml#Feature
        label: "Area of interest"
        doc: "Area of interest defined in GeoJSON format"
        inputBinding:
          position: 3
          valueFrom: |
            ${
              // Validate if type is Feature
              if (inputs.aoi.type !== "Feature") {
                throw "Invalid GeoJSON type: expected \"Feature\", got \"" + inputs.aoi.type + "\"";
              }
              // get the Feature geometry type
              return "Feature with id \"" + inputs.aoi.id + "\" is of type: " + inputs.aoi.geometry.type;
            }

      start_time:
        type: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#DateTime
        label: "Start Time"
        doc: "Start time in ISO 8601 format"
        inputBinding:
          position: 4
          valueFrom: |
            ${
              // Parse ISO datetime and extract parts
              var date = new Date(inputs.start_time.value);
              if (isNaN(date.getTime())) {
                throw "Invalid ISO 8601 date format for start_time.";
              }
              var dateParts = [
                "Date Breakdown:",
                "Year: " + date.getUTCFullYear(),
                "Month: " + (date.getUTCMonth() + 1),
                "Day: " + date.getUTCDate(),
                "Hour: " + date.getUTCHours(),
                "Minute: " + date.getUTCMinutes(),
                "Second: " + date.getUTCSeconds()
              ].join("\n * ");
              return dateParts;
            }

      product_uri:
        type: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URI
        label: "Product URI"
        doc: "Product URI in string format"
        inputBinding:
          position: 5
          valueFrom: |
            ${
              // parse the URI provided in the input
              var product_uri = inputs.product_uri.value;
              // Validate the URI format
              var uriPattern = /^(https?|ftp):\/\/[^\s/$.?#].[^\s]*$/i;
              if (!uriPattern.test(product_uri)) {
                throw "Invalid URI format: " + product_uri;
              }
              // Return the URI as a string
              return "Product URI: " + product_uri;
            }

    stdout: message
    outputs:
      echoed:
        outputBinding:
          glob: message
          loadContents: true
          outputEval: $(self[0].contents)
        type: string


  