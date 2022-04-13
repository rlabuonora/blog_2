---
title: Fábrica de funciones trigonométricas
author: ''
date: '2022-04-13'
slug: fabrica-de-funciones-trigonometricas
categories: []
tags: []
images: []
---




Estoy tratando de aprender algo de trigonometría. Una de las cosas que aprendí es que

$$ cos(90^\circ)=cos(\pi/2)=0 $$


La mayor parte de los ejercicios del libro que estoy usando usan grados en vez de radianes, pero las funciones trigonométricas de R usan radianes:

```r
cos(pi/2) # casi 0
```

```
## [1] 6.123234e-17
```

```r
cos(90) # nada que ver!
```

```
## [1] -0.4480736
```

¿Cómo podemos adaptar las funciones de R para que acepten grados en vez de radianes? Lo primero que encontré fue [esta respuesta en stackoverflow](https://stackoverflow.com/a/68925329).


```r
coss <- function(a){
  a=cos(a*pi/180)
  return(a)
}
sinn <- function(a){
  a= sin(a*pi/180)
  return(a)
}
tann <- function(a){
  a= tan(a*pi/180)
  return(a)
}
```



```r
library(testthat)

test_that("Solución de SO", {
  # Coseno de 90° es 0
  expect_equal(coss(90), 0, tolerance=1e-1)
  # Seno de 90° es 1
  expect_equal(sinn(90), 1, tolerance=1e-1)
  # Tangente de 45° es 1
  expect_equal(tann(45), 1, tolerance=1e-1)
})
```

```
## Test passed 🎉
```

Lo que hace esta solución es crear un `wrapper` en torno a las funciones nativas de R (`sin`, `cos` y `tan`). La única diferencia entre (`tann`, `sinn` y `coss`) es que cada una llama a su función correspondiente en base R.

Para reducir la repetición entre `coss`, `sinn` y `tann` podemos reescribirlas usando un idioma funcional que se llama [fábrica de funciones](https://adv-r.hadley.nz/function-factories.html).

Como R es un lenguaje funcional, las funciones son objetos. Se pueden asignar a variables, pasarse como argumentos a funciones y devolverse de funciones. 

Para implemetar esta solución, creamos una función `accept_degrees` que toma como argumento otra función que acepta radianes (`sin`, `cos` o `tan`)  y devuelve una función que acepta grados como argumento.

Después la usamos para crear las funciones que necesito: (`sin2`, `cos2` o `tan2`).


```r
accept_degrees <- function(f) {
  function(angle) {
    f(angle * pi / 180)
  }
}

sin2 <- accept_degrees(sin)
cos2 <- accept_degrees(cos)
tan2 <- accept_degrees(tan)
```

Para entender como funciona este código, es importante tener en mente un concepto importante, que es el tipado de una función. Esto es el `tipo` o `clase` de los argumentos que recibe y de los resultados que devuelve.


```r
library(testthat)

test_that("Solucion 1", {
  # Coseno de 90° es 0
  expect_equal(cos2(90), 0, tolerance=1e-1)
  # Coseno de 0° es 1
  expect_equal(cos2(0), 1, tolerance=1e-1)
  # Seno de 90° es 1
  expect_equal(sin2(90), 1, tolerance=1e-1)
  # Seno de 0° es 0
  expect_equal(sin2(0), 0, tolerance=1e-1)
  # Tangente de 0° es 0
  expect_equal(tan2(0), 0, tolerance=1e-1)
  # Tangente de 45° es 1
  expect_equal(tan2(45), 1, tolerance=1e-1)

})
```

```
## Test passed 🥇
```

Otra ventaja que tiene esto es que permite cambiar rápidamente la implementación del código que convierte los ángulos de grados a radianes. Primero factoreamos una función (`deg_to_rad`) para hacer la conversión:


```r
deg_to_rad <- function(angle) {
  angle * pi / 180
}

accept_degrees <- function(f) {
  function(angle) {
    f(deg_to_rad(angle))
  }
}

sin2 <- accept_degrees(sin)
cos2 <- accept_degrees(cos)
tan2 <- accept_degrees(tan)
```



Si encontramos otra implementación de `deg_to_rad_` que nos gusta más, podemos usarla fácilmente:


```r
library(units)
```

```
## udunits database from /Library/Frameworks/R.framework/Versions/4.1/Resources/library/units/share/udunits/udunits2.xml
```

```r
deg_to_rad <- function(angle) {
  
  angle <- set_units(angle, degree)
  units(angle) <- make_units(radian)
  return(angle)

}

accept_degrees <- function(f) {
  function(angle) {
    f(deg_to_rad(angle))
  }
}

sin2 <- accept_degrees(sin)
cos2 <- accept_degrees(cos)
tan2 <- accept_degrees(tan)
```


```r
library(testthat)

test_that("Solución final", {
  # Coseno de 90° es 0
  expect_equal(cos2(90), set_units(0, 1), tolerance=1e-1)
  # Coseno de 0° es 1
  expect_equal(cos2(0), set_units(1, 1), tolerance=1e-1)
  # Seno de 90° es 1
  expect_equal(sin2(90), set_units(1, 1), tolerance=1e-1)
  # Seno de 0° es 0
  expect_equal(sin2(0), set_units(0, 1), tolerance=1e-1)
  # Tangente de 0° es 0
  expect_equal(tan2(0), set_units(0, 1), tolerance=1e-1)
  # Tangente de 45° es 1
  expect_equal(tan2(45), set_units(1, 1), tolerance=1e-1)
})
```

```
## Test passed 🥇
```

