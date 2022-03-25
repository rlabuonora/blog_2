---
title: Scraping NBA data with rvest and purrr
author: ''
date: '2018-08-01'
slug: scraping-nba-data
categories: []
tags: ["R", "purrr"]
images: []
---




The NBA does a great job releasing statistics on every aspect of the game. Most teams have analytics experts crunching those numbers for insights to get a competitive advantage.

In this post I go through the process of scraping data from [basketball-reference.com](https://www.basketball-reference.com/) using the R package `rvest`. I also do some data munging with `purrr` and string interpolation with `glue`.


# NBA Reference
This website has statistics on every aspect of the game for a long time. In this post, I'll focus on individual player stats (Field Goal Percentage, Average Minutes, etc.) from the 2000/2001 season up to 2017/2018.

If you follow [this link](https://www.basketball-reference.com/leagues/NBA_2017_per_game.html), you can find the data for the 2017 season in an html table.

Html uses a special markup language to format the tables so that your browser can render it properly. Typically, an html table has this structure:


```html
<table>
  <th>Player</th>
  <td>Data<td>
</table>
```

To get this into an R data frame, you can use rvest. The first step is to get all the html from the page using read_html.


```r
library(rvest)
nba_url <- "https://www.basketball-reference.com/leagues/NBA_2017_per_game.html"
web_page <- read_html(nba_url)
```

Now we need to get the actual data from the table. `html_table` does just that:


```r
data <- html_table(web_page)
head(data[[1]])
```

```
## # A tibble: 6 x 30
##   Rk    Player Pos   Age   Tm    G     GS    MP    FG    FGA   `FG%` `3P`  `3PA`
##   <chr> <chr>  <chr> <chr> <chr> <chr> <chr> <chr> <chr> <chr> <chr> <chr> <chr>
## 1 1     Álex ~ SG    23    OKC   68    6     15.5  2.0   5.0   .393  1.4   3.6  
## 2 2     Quinc~ PF    26    TOT   38    1     14.7  1.8   4.5   .412  1.0   2.4  
## 3 2     Quinc~ PF    26    DAL   6     0     8.0   0.8   2.8   .294  0.2   1.2  
## 4 2     Quinc~ PF    26    BRK   32    1     15.9  2.0   4.8   .425  1.1   2.6  
## 5 3     Steve~ C     23    OKC   80    80    29.9  4.7   8.2   .571  0.0   0.0  
## 6 4     Arron~ SG    31    SAC   61    45    25.9  3.0   6.9   .440  1.0   2.5  
## # ... with 17 more variables: `3P%` <chr>, `2P` <chr>, `2PA` <chr>,
## #   `2P%` <chr>, `eFG%` <chr>, FT <chr>, FTA <chr>, `FT%` <chr>, ORB <chr>,
## #   DRB <chr>, TRB <chr>, AST <chr>, STL <chr>, BLK <chr>, TOV <chr>, PF <chr>,
## #   PTS <chr>
```

That was easy! html_table returns a list with all the tables in the web_page as a data_frame. What we want is the first element of that list.


```r
data <- data[[1]]
```


Let's inspect the data:


```r
str(data)
```

```
## tibble [619 x 30] (S3: tbl_df/tbl/data.frame)
##  $ Rk    : chr [1:619] "1" "2" "2" "2" ...
##  $ Player: chr [1:619] "Álex Abrines" "Quincy Acy" "Quincy Acy" "Quincy Acy" ...
##  $ Pos   : chr [1:619] "SG" "PF" "PF" "PF" ...
##  $ Age   : chr [1:619] "23" "26" "26" "26" ...
##  $ Tm    : chr [1:619] "OKC" "TOT" "DAL" "BRK" ...
##  $ G     : chr [1:619] "68" "38" "6" "32" ...
##  $ GS    : chr [1:619] "6" "1" "0" "1" ...
##  $ MP    : chr [1:619] "15.5" "14.7" "8.0" "15.9" ...
##  $ FG    : chr [1:619] "2.0" "1.8" "0.8" "2.0" ...
##  $ FGA   : chr [1:619] "5.0" "4.5" "2.8" "4.8" ...
##  $ FG%   : chr [1:619] ".393" ".412" ".294" ".425" ...
##  $ 3P    : chr [1:619] "1.4" "1.0" "0.2" "1.1" ...
##  $ 3PA   : chr [1:619] "3.6" "2.4" "1.2" "2.6" ...
##  $ 3P%   : chr [1:619] ".381" ".411" ".143" ".434" ...
...
```
Ok, so all the columns are read in as text. That's natural, since all html pages are text, so we need to convert the data to the correct data types. 

Most columns seem to be `numeric`, except `Player Name` which is a `character` vector, `Player Position` and `Team` which are `factors`.

One approach to correcting the data types is to use dplyr's mutate:


```r
library(dplyr)
data_1 <- data %>% 
  mutate(Rk = as.numeric(Rk),
         Pos = as.factor(Pos),
         Age = as.numeric(Age))
#       ...

str(select(data_1, Rk, Pos, Age))
```

```
## tibble [619 x 3] (S3: tbl_df/tbl/data.frame)
##  $ Rk : num [1:619] 1 2 2 2 3 4 5 6 7 8 ...
##  $ Pos: Factor w/ 7 levels "C","PF","PF-C",..: 7 2 2 2 1 7 1 1 2 2 ...
##  $ Age: num [1:619] 23 26 26 26 23 31 28 28 31 27 ...
```

But there's a better way. `mutate_at` applies a function to a list of columns.


```r
data_2 <- data %>% 
  mutate_at(vars(Tm, Pos), factor)

str(select(data_2, Tm, Pos))
```

```
## tibble [619 x 2] (S3: tbl_df/tbl/data.frame)
##  $ Tm : Factor w/ 32 levels "ATL","BOS","BRK",..: 21 30 7 3 21 26 19 18 27 12 ...
##  $ Pos: Factor w/ 7 levels "C","PF","PF-C",..: 7 2 2 2 1 7 1 1 2 2 ...
```

 The Columns need to be specified as a list of variables: `vars(Tm, Pos)`. In this case, the function applied is `factor`.

Repeat for all the numeric variables using the `:` notation to select all the columns from `G` to `PS.G`.


```r
data_3 <- data %>%
  mutate_at(vars(G:`PTS`, Age), as.numeric)
str(select(data_3, G:`PTS`, Age))
```

```
## tibble [619 x 26] (S3: tbl_df/tbl/data.frame)
##  $ G   : num [1:619] 68 38 6 32 80 61 39 62 72 61 ...
##  $ GS  : num [1:619] 6 1 0 1 80 45 15 0 72 5 ...
##  $ MP  : num [1:619] 15.5 14.7 8 15.9 29.9 25.9 15 8.6 32.4 14.3 ...
##  $ FG  : num [1:619] 2 1.8 0.8 2 4.7 3 2.3 0.7 6.9 1.3 ...
##  $ FGA : num [1:619] 5 4.5 2.8 4.8 8.2 6.9 4.6 1.4 14.6 2.8 ...
##  $ FG% : num [1:619] 0.393 0.412 0.294 0.425 0.571 0.44 0.5 0.523 0.477 0.458 ...
##  $ 3P  : num [1:619] 1.4 1 0.2 1.1 0 1 0 0 0.3 0 ...
##  $ 3PA : num [1:619] 3.6 2.4 1.2 2.6 0 2.5 0.1 0 0.8 0 ...
##  $ 3P% : num [1:619] 0.381 0.411 0.143 0.434 0 0.411 0 NA 0.411 0 ...
##  $ 2P  : num [1:619] 0.6 0.9 0.7 0.9 4.7 2 2.3 0.7 6.6 1.3 ...
##  $ 2PA : num [1:619] 1.4 2.1 1.7 2.2 8.2 4.4 4.5 1.4 13.8 2.7 ...
##  $ 2P% : num [1:619] 0.426 0.413 0.4 0.414 0.572 0.457 0.511 0.523 0.48 0.461 ...
##  $ eFG%: num [1:619] 0.531 0.521 0.324 0.542 0.571 0.514 0.5 0.523 0.488 0.458 ...
##  $ FT  : num [1:619] 0.6 1.2 0.3 1.3 2 1.4 0.7 0.2 3.1 0.4 ...
...
```

But wait, what about the rest of the years? You probably heard about the DRY principe: Don't Repeat Yourself. It'd be silly to write a whole script just to download data from another season, because most of the code would be the same. So we need to *reuse* our code to get data from the rest of the seasons.


To make our code more reusable, the first thing we need to do is build the url to get the html. We'll use a super cool package called `glue` for that. 


```r
library(glue)
name <- "Rafa"
glue("Hello, {name}")
```

```
## Hello, Rafa
```

I'm sure you get the idea. It's what programmer's call *string interpolation*.

For loops are used to *iterate* over collections, so we can repeat some process without copying the code. With a for loop, we can generate a vector of urls for every season we're interested in:
  

```r
base_url <- "https://www.basketball-reference.com/leagues/"
page <- "NBA_{year}_per_game.html"
urls <- vector("double", length(2000:2017))
for (year in 2000:2017) {
  urls[[year-1999]] <- glue(base_url, page) ## year -1999 gives 1, 2, 3, ...
}
head(urls)
```

```
## [1] "https://www.basketball-reference.com/leagues/NBA_2000_per_game.html"
## [2] "https://www.basketball-reference.com/leagues/NBA_2001_per_game.html"
## [3] "https://www.basketball-reference.com/leagues/NBA_2002_per_game.html"
## [4] "https://www.basketball-reference.com/leagues/NBA_2003_per_game.html"
## [5] "https://www.basketball-reference.com/leagues/NBA_2004_per_game.html"
## [6] "https://www.basketball-reference.com/leagues/NBA_2005_per_game.html"
```

Awesome! Now instead of creating a vector of urls, we'll create a list of data frames, one for every season.
  

```r
base_url <- "https://www.basketball-reference.com/leagues/"
page <- "NBA_{year}_per_game.html"
data <- list()

for (year in 2015:2017) {
  nba_url <- glue(base_url, page) 
  web_page <- read_html(nba_url)
  data[[year-2014]] <- html_table(web_page)[[1]]

}
str(data)
```

```
## List of 3
##  $ : tibble [675 x 30] (S3: tbl_df/tbl/data.frame)
##   ..$ Rk    : chr [1:675] "1" "2" "3" "4" ...
##   ..$ Player: chr [1:675] "Quincy Acy" "Jordan Adams" "Steven Adams" "Jeff Adrien" ...
##   ..$ Pos   : chr [1:675] "PF" "SG" "C" "PF" ...
##   ..$ Age   : chr [1:675] "24" "20" "21" "28" ...
##   ..$ Tm    : chr [1:675] "NYK" "MEM" "OKC" "MIN" ...
##   ..$ G     : chr [1:675] "68" "30" "70" "17" ...
##   ..$ GS    : chr [1:675] "22" "0" "67" "0" ...
##   ..$ MP    : chr [1:675] "18.9" "8.3" "25.3" "12.6" ...
##   ..$ FG    : chr [1:675] "2.2" "1.2" "3.1" "1.1" ...
##   ..$ FGA   : chr [1:675] "4.9" "2.9" "5.7" "2.6" ...
##   ..$ FG%   : chr [1:675] ".459" ".407" ".544" ".432" ...
##   ..$ 3P    : chr [1:675] "0.3" "0.3" "0.0" "0.0" ...
##   ..$ 3PA   : chr [1:675] "0.9" "0.8" "0.0" "0.0" ...
...
```

# Better iteration with map
Now our script does everything we want it to do. But there's a wrinkle we have to iron out. 

A lot of programming is about iteration, and every programming language supports for loops. R has a great way to make iteration cleaner with the `purrr` package. There's a whole chapter on iteration in [R for Data Science](http://r4ds.had.co.nz/iteration.html), which is a must read for anyone interested in R.

Our script has to repeat the same steps for every year from 2000 to 2017. That's a job for `map`! `map` takes a `list` and applies a function to every element of the list. 

For example, here we apply the `head` function to a list of data frames to get the first 6 lines of each one:
  

```r
my_list <- list(mtcars, iris)
purrr::map(my_list, head)
```

```
## [[1]]
##                    mpg cyl disp  hp drat    wt  qsec vs am gear carb
## Mazda RX4         21.0   6  160 110 3.90 2.620 16.46  0  1    4    4
## Mazda RX4 Wag     21.0   6  160 110 3.90 2.875 17.02  0  1    4    4
## Datsun 710        22.8   4  108  93 3.85 2.320 18.61  1  1    4    1
## Hornet 4 Drive    21.4   6  258 110 3.08 3.215 19.44  1  0    3    1
## Hornet Sportabout 18.7   8  360 175 3.15 3.440 17.02  0  0    3    2
## Valiant           18.1   6  225 105 2.76 3.460 20.22  1  0    3    1
## 
## [[2]]
##   Sepal.Length Sepal.Width Petal.Length Petal.Width Species
## 1          5.1         3.5          1.4         0.2  setosa
## 2          4.9         3.0          1.4         0.2  setosa
## 3          4.7         3.2          1.3         0.2  setosa
## 4          4.6         3.1          1.5         0.2  setosa
## 5          5.0         3.6          1.4         0.2  setosa
## 6          5.4         3.9          1.7         0.4  setosa
```

Instead of `head`, which is a predefined function, you can use your own functions:
  

```r
my_list <- list(mtcars, iris)
my_func <- function(data_frame) { print("Hello from my fun!")}
purrr::map(my_list, my_func)
```

```
## [1] "Hello from my fun!"
## [1] "Hello from my fun!"
```

```
## [[1]]
## [1] "Hello from my fun!"
## 
## [[2]]
## [1] "Hello from my fun!"
```

When applying map, you need to figure out our initial list to iterate over, and the function we want to apply to it's elements in every iteration. The first part is easy, to get a list of seasons, we convert a numeric vector into a list like: `as.list(2000:2017)`.


Now we need a function that takes one year and does the job for that year. Something like:
  

```r
get_player_data <- function(year) {
  base_url <- "https://www.basketball-reference.com/leagues/"
  page <- "NBA_{year}_per_game.html"
  # Download data
  nba_url <- glue(base_url, page) 
  # extract the data frame from the table
  web_page <- read_html(nba_url)
  data <- html_table(web_page)[[1]]
  # return a data frame
  data
}

data.14 <- get_player_data(2014)
head(data.14)
```

```
## # A tibble: 6 x 30
##   Rk    Player Pos   Age   Tm    G     GS    MP    FG    FGA   `FG%` `3P`  `3PA`
##   <chr> <chr>  <chr> <chr> <chr> <chr> <chr> <chr> <chr> <chr> <chr> <chr> <chr>
## 1 1     Quinc~ SF    23    TOT   63    0     13.4  1.0   2.2   .468  0.1   0.2  
## 2 1     Quinc~ SF    23    TOR   7     0     8.7   0.9   2.0   .429  0.3   0.7  
## 3 1     Quinc~ SF    23    SAC   56    0     14.0  1.1   2.3   .472  0.0   0.2  
## 4 2     Steve~ C     20    OKC   81    20    14.8  1.1   2.3   .503  0.0   0.0  
## 5 3     Jeff ~ PF    27    TOT   53    12    18.1  2.7   5.2   .520  0.0   0.0  
## 6 3     Jeff ~ PF    27    CHA   25    0     10.2  0.9   1.6   .550  0.0   0.0  
## # ... with 17 more variables: `3P%` <chr>, `2P` <chr>, `2PA` <chr>,
## #   `2P%` <chr>, `eFG%` <chr>, FT <chr>, FTA <chr>, `FT%` <chr>, ORB <chr>,
## #   DRB <chr>, TRB <chr>, AST <chr>, STL <chr>, BLK <chr>, TOV <chr>, PF <chr>,
## #   PTS <chr>
```

# Pipes
Pipes are a well known feature in the `tidyverse`, so I won't go into detail of how they work. We could turn our function into a set of pipes easily except for this line: `data <- html_table(web_page)[[1]]`. 

We're actually calling two functions in that line: `html_table` with the `web_page` argument and `[[` with `1` as an argument. 

```r
web_page <- read_html(nba_url)
tbl_lst <- html_table(web_page)
df <- `[[`(tbl_lst, 1)
```
  
So we can pipe it like this:


```r
df_2 <- web_page %>% 
 html_table %>% 
 `[[`(1)
```

Finally, we re-write our get_player_data function as:
  

```r
get_player_data <- function(year) {
  base_url <- "https://www.basketball-reference.com/leagues/"
  page <- "NBA_{year}_per_game.html"
  
  glue(base_url, page) %>% 
    read_html %>% 
    html_table %>% 
    `[[`(1)
}

df.14 <- get_player_data(2014)
head(df.14)
```

```
## # A tibble: 6 x 30
##   Rk    Player Pos   Age   Tm    G     GS    MP    FG    FGA   `FG%` `3P`  `3PA`
##   <chr> <chr>  <chr> <chr> <chr> <chr> <chr> <chr> <chr> <chr> <chr> <chr> <chr>
## 1 1     Quinc~ SF    23    TOT   63    0     13.4  1.0   2.2   .468  0.1   0.2  
## 2 1     Quinc~ SF    23    TOR   7     0     8.7   0.9   2.0   .429  0.3   0.7  
## 3 1     Quinc~ SF    23    SAC   56    0     14.0  1.1   2.3   .472  0.0   0.2  
## 4 2     Steve~ C     20    OKC   81    20    14.8  1.1   2.3   .503  0.0   0.0  
## 5 3     Jeff ~ PF    27    TOT   53    12    18.1  2.7   5.2   .520  0.0   0.0  
## 6 3     Jeff ~ PF    27    CHA   25    0     10.2  0.9   1.6   .550  0.0   0.0  
## # ... with 17 more variables: `3P%` <chr>, `2P` <chr>, `2PA` <chr>,
## #   `2P%` <chr>, `eFG%` <chr>, FT <chr>, FTA <chr>, `FT%` <chr>, ORB <chr>,
## #   DRB <chr>, TRB <chr>, AST <chr>, STL <chr>, BLK <chr>, TOV <chr>, PF <chr>,
## #   PTS <chr>
```

Good, now we're all set for using `map`:


```r
list_of_data_frames <- as.list(2000:2017) %>% 
  purrr::map(get_player_data)
  
str(list_of_data_frames)
```

```
## List of 18
##  $ : tibble [517 x 30] (S3: tbl_df/tbl/data.frame)
##   ..$ Rk    : chr [1:517] "1" "1" "1" "2" ...
##   ..$ Player: chr [1:517] "Tariq Abdul-Wahad" "Tariq Abdul-Wahad" "Tariq Abdul-Wahad" "Shareef Abdur-Rahim" ...
##   ..$ Pos   : chr [1:517] "SG" "SG" "SG" "SF" ...
##   ..$ Age   : chr [1:517] "25" "25" "25" "23" ...
##   ..$ Tm    : chr [1:517] "TOT" "ORL" "DEN" "VAN" ...
##   ..$ G     : chr [1:517] "61" "46" "15" "82" ...
##   ..$ GS    : chr [1:517] "56" "46" "10" "82" ...
##   ..$ MP    : chr [1:517] "25.9" "26.2" "24.9" "39.3" ...
##   ..$ FG    : chr [1:517] "4.5" "4.8" "3.4" "7.2" ...
##   ..$ FGA   : chr [1:517] "10.6" "11.2" "8.7" "15.6" ...
##   ..$ FG%   : chr [1:517] ".424" ".433" ".389" ".465" ...
##   ..$ 3P    : chr [1:517] "0.0" "0.0" "0.1" "0.4" ...
##   ..$ 3PA   : chr [1:517] "0.4" "0.5" "0.1" "1.2" ...
...
```

# Another functional idiom: Reduce

Map takes list and returns a list. In our script, it takes a list of numbers as input and returns a list of data frames. We now need to roll all those data frames into a single data frame.

That's what reduce does. It takes a list and applies a function to consequtive pairs. accumulating the results. 
  

```r
lst <- list(1, 2, 3, 4) 
purrr::reduce(lst, sum) # don't do this in real life!
```

```
## [1] 10
```
  
Of course, since R's sum is vectorized you don't ever need to do that,

Reduce works great with map:
  

```r
lst <- list(1, 2, 3, 4) 
# Find the sum of the square root of 1, 2, 3, 4
purrr::map(lst, sqrt) %>% 
  purrr::reduce(sum)
```

```
## [1] 6.146264
```

Another example: get the sum of the rows in a list of data frames:

```r
list(mtcars, iris) %>% 
  purrr::map(nrow) %>% 
  purrr::reduce(sum)
```

```
## [1] 182
```

In our case, what we need it to use `reduce` with bind_rows, so we accumulate all the rows in our data_frame into a single one.

Putting all the pieces together in the final script:

```r
library(glue)
library(purrr)
library(dplyr)
library(rvest)

# Download data table from basketball reference
get_player_data <- function(year) {
  
  base_nba_url <- "https://www.basketball-reference.com/leagues/NBA_{year}_per_game.html"
  
  glue(base_nba_url) %>% 
    read_html() %>% 
    html_table() %>% 
    `[[`(1) %>% 
    mutate(Year = year)
}

data <- as.list(2000:2018) %>% 
  purrr::map(get_player_data) %>% 
  purrr::reduce(bind_rows) %>% 
  mutate_at(vars(G:`PS/G`, Age), as.numeric) %>% 
  mutate_at(vars(Tm, Pos), factor)
```

# What to do with the data
  - https://fastbreakdata.com/classifying-the-modern-nba-player-with-machine-learning-539da03bb824
  - https://www.reddit.com/r/nba/comments/6pp8jo/ocrethinking_basketball_positions_with_machine/
  - http://cs229.stanford.edu/proj2012/Wheeler-PredictingNBAPlayerPerformance.pdf
  
  + Effect of injury
  + Regression candidates in a team
  + PCA
  + player stats predict team offense and defense rating?
  + predict wins based on offense and defense rating
