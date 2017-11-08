# backBurner
A simple function to send data and instructions from a main environment/console to a secondary R session. Data is stored in an RData file at the end.

The expression included have to: 
a) list all the needed variables, 
b) be enclosed in {} and 
c) have the result in a variable different than the initial ones

Here some examples:
load expression: 

  expr <- expression({seis;plotF();edgewc+edgew})

  exprX <- expression({x <- function(r) {1+3};x})

  backBurner(exprX, Substitute=FALSE)

  backBurner({x <- function(r) {1+3};x})

  backBurner({p0<- proc.time(); Sys.sleep(30);p1 <- proc.time(); cat(p1-p0)})
