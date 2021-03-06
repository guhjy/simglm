% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/err_sim.r
\name{sim_err_single}
\alias{sim_err_single}
\title{Function that simulates errors.}
\usage{
sim_err_single(error_var, n, with_err_gen, arima = FALSE,
  lvl1_err_params = NULL, arima_mod = list(NULL), ther = c(0, 1),
  ther_sim = FALSE, ...)
}
\arguments{
\item{error_var}{Numeric scalar of error variance}

\item{n}{Cluster sample size.}

\item{with_err_gen}{The generating function used.}

\item{arima}{TRUE/FALSE flag indicating whether residuals should 
be correlated. If TRUE, must specify a valid model to pass to 
arima.sim via the arima_mod argument. 
See \code{\link{arima.sim}} for examples.}

\item{lvl1_err_params}{Additional values that need to be passed to the 
function called from with_err_gen.}

\item{arima_mod}{A list indicating the ARIMA model to pass to arima.sim. 
See \code{\link{arima.sim}} for examples.}

\item{ther}{A vector of length two that specifies the theoretical mean and 
standard deviation of the with_err_gen. This would commonly be used
to standardize the generating variable to have a mean of 0 and
standard deviation of 1 to meet model assumptions. The variable
is then rescaled to have the variance specified by error_var.}

\item{ther_sim}{A TRUE/FALSE flag indicating whether the error simulation 
function should be simulated, that is should the mean and standard deviation
used for standardization be simulated.}

\item{...}{Not currently used.}
}
\description{
Input error simulation parameters and outputs simulated errors.
}
\details{
Simulates error term for single level regression models.
}
