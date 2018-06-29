# Resource Audit

This plugin conducts audits on the completeness of metadata for ArchivesSpace Resources according to the guidelines laid out by the University of Denver Libraries Division of Special Collections and Archives. Each collection is assigned one of three levels of resource and component description; this property is assigned as a user-defined metadata element at the Resource level. The plugin checks which of the three levels has been assigned to the requested Resource, then performs audit checks based on the DU guidelines for passage, partial passage (i.e. a value is assigned but may require further QA checking by an archivist), or failure (no value or insufficient values assigned).

The plugin consists of a backend API call returning audit outcomes and values (serialized in JSON) and a frontend to the API in the staff interface.

Currently the plugin only checks metadata at the Resource level; further enhancements will allow for checking of Top Containers and other component records, in line with our metadata completeness guidelines.

# Levels of Resource Description at DU

## Resources

### Level 1

* Title
* Local classification number, to uniquely identify the Resource within its collection area
* Level of description (required by ArchivesSpace)
* A date of creation of the records, if known
* The extent of the records (this can be calculated by ArchivesSpace if the resource's container records have container profiles)
* An Abstract note
* An agent link identifying the creator or immediate source of the collection materials, if known
* At minimum, three subject headings of any type

### Level 2

All of the Level 1 elements, and additionally:

* A Scope/Contents and Biographical/Historical note
* An External Document link to the corresponding digital repository collection, if any of the collection materials have been digitized in some way

## Levels of description for Resource component records

### Level 1

All Resources should have at minimum the following components and metadata:

* One Top Container record per barcoded physical item, with the following information attached:

  * Barcode
  * Component ID
  * Container Profile (for calculating extent)
  * As much arrangement and description as is needed to contextualize the Top Containers within the resource. In the simplest form, this is done by creating one Archival Object record per Top Container. Larger and more complex collections may require arrangement at the Series level to meet the Level 1 specifications.

### Level 2

The Level 1 specifications, plus folder-level records consisting of a Title, Component Identifier, Dates (if known), and Creator information (if known)

### Level 3

The Level 2 specifications, plus item-level descriptions suitable for MODS export and ingest in the digital repository.
