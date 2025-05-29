# Application package patterns based on data stage-in and stage-out behaviors commonly used in EO workflows

Application packages expose several patterns in terms of data access and result publishing.

This repository contains CWL descriptions implementing these patterns to verification and validation activities

The patterns are:

## one input/one output

The CWL includes: 
- one input parameter of type `Directory`
- one output parameter of type `Directory`

This scenario typically takes one input, applies an algorithm and produces a result

Implementation: process the NDVI taking as input a Landsat-9 acquisition

## two inputs/one output

The CWL includes: 
- two input parameters of type `Directory`
- one output parameter of type `Directory`

This scenario typically takes as input one pre-event acquisition, one post-even acquisition, applies an algorithm and produces a result

Implementation: process the NDVI for two dates taking input two Landsat-9 acquisitions producing a STAC Catalog with two STAC Items

## scatter on inputs/one output

The CWL includes: 
- scatter on an input parameter of type `Directory[]`
- one output parameter of type `Directory`

This scenario typically takes as input a stack of acquisitions, applies an aggregation algorithm and produces a result

Implementation: process the NDVI taking as input a stack of Landsat-9 acquisitions producing a STAC Catalog with n STAC Items

## one input/two outputs

The CWL includes: 
- one input parameter of type `Directory`
- two output parameters of type `Directory`

This scenario takes as input an acquisition, applies two algorithms and generates two outputs.

Implementation: process the NDVI and NDWI taking as input a Landsat-9 acquisition. The output include two STAC Catalogs, each with a single STAC Item

## one input/scatter on outputs

The CWL includes: 
- one input parameter of type `Directory`
- scatter on an output parameter of type `Directory[]`

This scenario takes as input an acquisition, applies an algorithm and generates several outputs

Implementation: process the NDVI and NDWI taking as input a Landsat-9 acquisition and generating a stack of STAC Catalogs

## one input, no output

The CWL includes: 
- one input parameter of type `Directory`
- there are no output parameters of type `Directory`

This corner-case scenario takes as input an acquisition, applies an algorithm and generates an output that is not a STAC Catalog

Implementation: derive the NDVI mean taking as input a Landsat-9 acquisition

## optional inputs, one output

The CWL includes: 
- one optional input parameter of type `Directory?`
- one output parameter of type `Directory`

This scenario may take as input an acquisition, applies an algorithm and generates an output

Implementation: process the NDVI taking as input a Landsat-9 acquisition

## one input, optional output

The CWL includes: 
- one input parameter of type `Directory`
- one output parameter of type `Directory?`

This scenario takes as input an acquisition, applies an algorithm and may or may not generate and output 

Implementation: process the NDVI taking as input a Landsat-9 acquisition with a parameter to create or not the output

## one input, optional outputs

The CWL includes: 
- one input parameter of type `Directory`
- output parameter of type `Directory[]?`

This scenario takes as input an acquisition, applies an algorithm and may or may not generate outputs 