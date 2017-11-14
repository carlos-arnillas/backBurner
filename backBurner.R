# Pet project
# load expression: it has to be always a) list all the needed variables,
# b) be enclosed in {} and have the result in a variable different than the initial ones
# expr <- expression({seis;plotF();edgewc+edgew})
# exprX <- expression({x <- function(r) {1+3};x})
# backBurner(exprX, Substitute=FALSE)
# backBurner({x <- function(r) {1+3};x})
# backBurner({p0<- proc.time(); Sys.sleep(30);p1 <- proc.time(); cat(p1-p0)})

externalBurner <- function(expr=NULL, Substitute=TRUE, name=NULL) {
  backBurner(expr=NULL, Substitute=TRUE, name=NULL, external=TRUE)
}

backBurner <- function(expr=NULL, Substitute=TRUE, name=NULL, external=FALSE) {
  # get the environment and the list of variables in it
  pos <- .GlobalEnv
  lvars <- ls(pos=pos)
  # load the list of loaded packages
  lloaded <- (.packages())
  textLibs <- paste0("library(",lloaded,")")
  # deparse the instructions and make them a character vector without beginning/end
  texpr <- if (Substitute[1]) deparse(substitute(expr)) else deparse=deparse(expr)
  # if nothing in expr, look in the clipboard
  if (is.null(texpr) || texpr == "NULL") {
    conpipe <- pipe("pbpaste")
    texpr <- suppressMessages(scan(conpipe,character(),sep="\n"))
    close(conpipe)
  }
  if (is.null(texpr)) stop("'expr' argument and clipboard are empty.")
  texpr <- texpr[c(-1,-length(texpr))]
  texpr <- paste0(texpr,collapse="\n")
  
  # find the variables that have to be saved
  lvarsExp <- unlist(lapply(lvars, function(x) if (any(grepl(sprintf("\\<%s\\>",gsub("\\.","\\.",x)),
                                                             texpr))) x else NULL))
  if (any(lvarsExp == "conLog__")) stop("Sorry... the only variable name you cannot use is conLog__.")
  
  # create the file names
  fnBase <- tempfile(pattern=paste0("back.running.",sprintf("%s.", name)), tmpdir=getwd())
  fnData <- paste0(fnBase,".RData")
  fnSc <- paste0(fnBase,".R")
  fnLog <- paste0(fnBase,".log.txt")
  
  # now put all together in a text file
  scLines <- c(sprintf("Back burner %s\n\n", name),
               "# Creating a message to be shown in the screen at the end",
               sprintf("on.exit(system(\"osascript -e 'tell app \\\"Finder\\\" to display dialog \\\"Back Burner Done!\n%s\\\"'\"))",fnBase),
                "# setting the log file",
                sprintf('conLog__ <- file("%s", open="wt")',fnLog),
               'sink(file=conLog__, append=TRUE)',
               'sink(file=conLog__, append=TRUE, type="message")',
                "# Loading libraries", 
                textLibs,
                "# Loading variables\n",
                sprintf('load("%s")',fnData),
                "# Loading instructions",
                texpr,
                "# saving results",
                sprintf('save(list=setdiff(ls(),c(%s)), file="%s")',paste0('"', 
                                                                             c("conLog__",lvarsExp),'"',
                                                                             collapse=","), fnData),
                "# and a closing message",
                sprintf("cat('\n========================================\nBack burner %s\n", name),
                sprintf("cat('\n========================================\nScript completed!\\n Data available in %s\\nLog report in %s\n')",fnData,fnLog),
                "# repeated after sink has stopped, so it bounce back to the main R code.",
                "sink(file=NULL)",
                sprintf("cat('\n========================================\nScript completed!\\n Data available in %s\\nLog report in %s\n')",fnData,fnLog)
               )
  
  # Create a temporary script and the input data
  save(list=lvarsExp,file=fnData)
  writeLines(scLines, con=fnSc)
  # Calling the external function if needed
  if (external) {
    cat(sprintf("Files ready to be executed at %s.*", fnBase))
    invisible(fnBase)
  } else {
    system(sprintf("cd %s;Rscript %s",getwd(),fnSc), wait=FALSE)
    cat(sprintf("Back burning... wait for a bit. Results will be at %s.RData", fnBase))
    invisible(fnData)
  }
}
