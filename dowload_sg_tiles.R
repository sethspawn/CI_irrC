rm(list = ls())

#====================================================================================================
# load required packages, installing any that have not yet been installed

packages = c(
  "xml2",
  "rvest",
  "future.apply"
)

install.packages(setdiff(packages, rownames(installed.packages()))) 
lapply(packages, require, character.only = TRUE)

#===============================================================================
main_url = 'https://files.isric.org'
parent_dir = 'soilgrids/latest/data'

variable = 'ocs'
depth = '0-30cm'
metric = 'Q0.95'

#===============================================================================
layer = paste(variable, depth, metric, sep = '_')

URL = paste(main_url, parent_dir, variable, layer, sep = '/')

sub_dirs = html_attr(html_nodes(read_html(URL), "a"), "href")
sub_dirs = sub_dirs[!grepl(paste(parent_dir, variable, sep = '/'), sub_dirs)]

dir.create(layer)

#===============================================================================

plan(multisession)

# iterate through each subdirectory
future_lapply(sub_dirs, function(sub_dir){
  
  files = html_attr(html_nodes(read_html(paste(URL, sub_dir, sep = '/')), "a"), "href")
  files = files[grepl('.tif', files)]
  
  #Lapply incase more than one tiff
  lapply(files, function(file){
    
    download.file(paste0(paste(URL, sub_dir, sep = '/'), file), file.path(layer, file), mode="wb")
    
  })
  
})


# from: https://github.com/Envirometrix/BigSpatialDataR
tmp.lst = list.files(path = file.path(layer),
                     pattern = ".tif$",
                     full.names = T,
                     recursive = T)


out.tmp <- tempfile(fileext = ".txt")
vrt.tmp <- tempfile(fileext = ".vrt")
cat(tmp.lst, sep="\n", file=out.tmp)
system(paste0('gdalbuildvrt -input_file_list ', out.tmp, ' ', vrt.tmp))
system(paste0('gdalwarp ', vrt.tmp, 
              ' \"./',layer,'.tif\" ', 
              '-ot \"Int16\" -dstnodata \"-32767\" -co \"BIGTIFF=YES\" ',  
              '-multi -wm 2000 -co \"COMPRESS=DEFLATE\" -overwrite ',
              '-r \"near\" -wo \"NUM_THREADS=ALL_CPUS\"'))

require(raster)
r = raster(paste0(layer,'.tif'))
plot(r)

