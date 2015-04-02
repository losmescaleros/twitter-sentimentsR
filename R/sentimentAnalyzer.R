# Include necessary packages
# In order to run the demo, you must install the project's package. To do this,
# use setwd() to set working directory to the extracted location of the project,
# then run the following lines. After the package is installed, you may run
# > demo(sentiments, "twitterSentimentsR")
sentimentsPkg = sprintf("%s%s", getwd(), "/twitterSentimentsR_1.0.tar.gz")
install.packages(sentimentsPkg, repos=NULL, type="source")
require("twitterSentimentsR")

library("streamR")
library("ROAuth")
library("tm")
library("SnowballC")
library("devtools")
library("ff")
library("rJava")
install_github("jwijffels/RMOA", subdir="RMOAjars/pkg")
install_github("jwijffels/RMOA", subdir="RMOA/pkg")
require("RMOA")
library("rpart")
library("ROCR")

setupTwitterOauth = function(consumerKey, consumerSecret){
  OAuthFactory$new(consumerKey = consumerKey,
                           consumerSecret = consumerSecret,
                           requestURL = "https://api.twitter.com/oauth/request_token",
                           accessURL = "https://api.twitter.com/oauth/access_token",
                           authURL = "https://api.twitter.com/oauth/authorize")
}

connectToTwitter = function(my_oauth){
  my_oauth$handshake(cainfo = system.file("CurlSSL", "cacert.pem", package = "RCurl"))
}

captureTweets = function(track, oauth, outFile, numTweets){
  if(oauth$handshakeComplete){
    filterStream(file=outFile, track=track, tweets=numTweets, oauth=oauth, language="en")
  }
  else{
    print("Error: OAuth handshake not complete")
  }
}

removeTwitterSyntax = function(tweets){
  # Get rid of emoji by converting to ASCII
  tweets.clean = iconv(tweets, "latin1", "ASCII", sub="")
  tweets.clean = gsub("[[:cntrl:]]", "", tweets.clean)
  # Remove retweet stuff
  tweets.clean = gsub("(RT|via)((?:\\b\\W*@\\w+)+)", "", tweets.clean)
  # Remove reply syntax
  tweets.clean = gsub("@\\w+", "", tweets.clean)
  return(tweets.clean)
}

cleanTweets = function(tweets){
  tweets.clean = tolower(tweets)
  tweets.clean = gsub("[[:punct:]]", "", tweets.clean)
  tweets.clean = gsub("[[:digit:]]", "", tweets.clean)
  tweets.clean = gsub("http\\w+", "", tweets.clean)
  return(tweets.clean)
}

cleanCorpus = function(corpus){  
  # Remove stop words
  corpus = tm_map(corpus, removeWords, stopwords("english")) 
  # Perform stemming. this is broken...
  corpus = tm_map(corpus, stemDocument)
  # Remove white space
  corpus = tm_map(corpus, stripWhitespace)
  return(corpus)
}

convertToDf = function(corpus, confidence){
  docMatrix = TermDocumentMatrix(corpus)
  
  docMatrix.clean = removeSparseTerms(docMatrix, confidence)
  matrix = as.matrix(docMatrix.clean)
  df = as.data.frame(t(matrix))
  df = df[which(df$love >= 1) || which(df$hate >= 1),]
  
  df[,"Class"] = ifelse(df$love, "love", "hate")
  return(df)
}
