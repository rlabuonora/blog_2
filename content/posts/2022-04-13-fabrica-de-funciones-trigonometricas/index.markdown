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

test_that("Coseno de 90° es 0", {
  expect_equal(coss(90), 0, tolerance=1e-1)
})
```

```
## Test passed 🥇
```

```r
test_that("Seno de 90° es 1", {
  expect_equal(sinn(90), 1, tolerance=1e-1)
})
```

```
## Test passed 🥳
```

```r
test_that("Tangente de 45° es 1", {
  expect_equal(tann(45), 1, tolerance=1e-1)
})
```

```
## Test passed 🌈
```

Lo que hace esta solución es crear un `wrapper` en torno a las funciones nativas de R (`sin`, `cos` y `tan`). Funciona, pero las tres funciones (`tann`, `sinn` y `coss`) son muy parecidas). La única diferencia entre las ellas es que cada una llama una función distinta.

Para reducir la repetición entre `coss`, `sinn` y `tann` podemos reescribirlas usando un idioma funcional que se llama [https://adv-r.hadley.nz/function-factories.html](fábrica de funciones).

Como R es un lenguaje funcional, las funciones son objetos. Se pueden asignar a variables, pasarse como argumentos a funciones y devolverse de funciones. 

Para implemetar esta solución, creamos una función `accept_degrees` que toma como argumento otra función que acepta radianes como argumento (`sin`, `cos` o `tan`)  y devuelve una función que acepta grados como argumento.


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

Para entender esto es importante tener en mente un concepto importante sobre funciones, que a veces no esta enfatizado en el mundo R, que es la `signature` de una función. Esto es el `tipo` o `clase` de los argumentos y sus resultados.

`accept_degrees` lleva como argumento una función (`f`) que toma como argumento un ángulo medido en radianes, y da como resultado una función que toma como argumento un ángulo medido en grados.


```r
library(testthat)

test_that("cos2", {
  # Coseno de 90° es 0
  expect_equal(cos2(90), 0, tolerance=1e-1)
  # Coseno de 0° es 1
  expect_equal(cos2(0), 1, tolerance=1e-1)
})
```

```
## Test passed 🎉
```

```r
test_that("sin2", {
  
  # Seno de 90° es 1
  expect_equal(sin2(90), 1, tolerance=1e-1)
  # Seno de 0° es 0
  expect_equal(sin2(0), 0, tolerance=1e-1)
  
})
```

```
## Test passed 🥇
```

```r
test_that("tan2", {
  # Tangente de 0° es 0
  expect_equal(tan2(0), 0, tolerance=1e-1)
  # Tangente de 45° es 1
  expect_equal(tan2(45), 1, tolerance=1e-1)

})
```

```
## Test passed 🌈
```

Otra ventaja que tiene esto es que permite cambiar rápidamente la implementación del cambio entre radianes y ángulos. Vamos a factorer una función (`deg_to_rad`) para hacer la conversión:


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



Ahora encontré otra forma de hacer la conversión que puede (?) ser mejor.


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

test_that("cos2", {
  # Coseno de 90° es 0
  expect_equal(cos2(90), set_units(0, 1), tolerance=1e-1)
  # Coseno de 0° es 1
  expect_equal(cos2(0), set_units(1, 1), tolerance=1e-1)
})
```

```
## Test passed 🎉
```

```r
test_that("sin2", {
  
  # Seno de 90° es 1
  expect_equal(sin2(90), set_units(1, 1), tolerance=1e-1)
  # Seno de 0° es 0
  expect_equal(sin2(0), set_units(0, 1), tolerance=1e-1)
  
})
```

```
## Test passed 🥳
```

```r
test_that("tan2", {
  # Tangente de 0° es 0
  expect_equal(tan2(0), set_units(0, 1), tolerance=1e-1)
  # Tangente de 45° es 1
  expect_equal(tan2(45), set_units(1, 1), tolerance=1e-1)

})
```

```
## Test passed 🎉
```

