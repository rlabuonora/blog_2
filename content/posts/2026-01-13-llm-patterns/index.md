---
title: LLM Patterns
author: ''
date: '2026-01-13'
slug: []
categories: []
tags: []
images: []
---

Los modelos de lenguaje son la tecnología que estábamos esperando. No sabemos si vinieron a salvarnos o a confirmar nuestra obsolecencia pero es imposible permanecer ajeno a lo que están haciendo y preguntarse que implican a futuro. En este posteo explico 4 patrones de uso que me parecen para acelerar la llegada del futuro. El tiempo dirá si es buena idea o no.

## El Minion 

Algunos les dicen por favor y gracias, pero solo los usan para evitar tareas ingratas. Claude Code está prendiendo fuego X estos días, es el caso de uso típico para el Minion pattern. 

Recientemente pasé de copiar y pegar código de ChatGPT a Codex en Visual Studio y la aceleración es brutal. De a poco me vuelven ideas de proyectos que se me fueron ocurriendo con los años pero nunca hice porque llevaban demasiado tiempo, supongo que los iré haciendo en estos meses porque el costo de programar pequeñas herramientas bajó dramáticamente. 

<!--  

Aquí una lista mínima:

- Juego para aprender geografía con shapefiles.
- Conversor video/audio a texto.
- El sitio web de un Diario ficticio.

-->


## El Maestro

El objetivo de este patrón es que el usuario absorba el conocimiento de un documento (mensaje). La tecnología __legacy__ (texto, audio, video) tiene un sesgo hacia la absorción pasiva de información. Los modelos de lenguaje permiten que el usuario tenga un rol activo, lo que permite absorber información (recibir el mensaje) de forma mucho más eficiente.

En esta modalidad, el modelo sondea al usuario para determinar el estado de su conocimiento del mensaje y promptea __al usuario__ con el objetivo de replicar el mensaje en su cerebro. El modelo genera el mínimo contenido necesario que sea 1) novedoso para el usuario, 2) "correcto" en el sentido de encontrarse en el mensaje original.

## El coach 

El objetivo de este patrón es entrenar al usuario para mejorar su performance en una habilidad específica. Esta habilidad mejora en base a sesiones de entrenamiento. El modelo sugiere objetivos, métricas y actividades para estructurar un sistema de práctica deliberada al nivel de exigencia que induce mejoras en la performance con el paso del tiempo. Este sistema facilita la repetición espaciada y permite mantener la coherencia temporal en el mediano plazo. 

Esto es especialmente útil para desarrollar habilidades que requieren plazos considerables para mejorar (estado físico, música, matemática). En estos dominios, es fácil perder la motivación si sentimos que vamos a la deriva, los modelos de lenguaje nos ayudan a mantener el rumbo y evaluar si estamos avanzando o no hacia nuestros objetivos.

## El espejo

Aclara los pensamientos del usuario. Estimula la elaboración e integración de pensamientos.
