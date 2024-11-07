stopwords <- readr::read_csv("data-raw/stopwords.csv")

usethis::use_data(stopwords, overwrite = TRUE)
