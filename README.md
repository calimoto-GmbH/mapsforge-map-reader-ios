# .map reader

### general structure
```
 # meta data
 file header

 # sub-files
 for each sub-file   
    # tile index segment   
    tile index header   
    tile index entries    

    # tile data segment   
    for each tile       
        tile header       
        for each POI           
            POI data       
        for each way           
            way properties           
            way data
```


## Detailview of mapfile
[map file specification from the origin project mapsforge](https://github.com/mapsforge/mapsforge/blob/master/docs/Specification-Binary-Map-File.md)
