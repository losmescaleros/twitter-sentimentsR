## ---- pauseFunction ----
pause <- function(){
  invisible(readline("\nPress <return> to continue: "))
}
## ---- prompt for credentials ----
promptForCred = function(){
  consumerKey = readline("What is your Twitter consumer key? ")
  consumerSecret = readline("What is your Twitter consumer secret? ")
}

## The following demo will show how to classify tweets from Twitter using
## R. We will walk through the various steps of the sentiment classification 
## process, including data retrieval, data pre-processing, feature construction
## and selection, and finally, modeling and prediction.

pause()

## Data Retrieval

## First, we'll need your Twitter API credentials.
promptForCred()
# Construct the OAuth object
demoOauth = setupTwitterOauth(consumerKey, consumerSecret)
# Handshake with Twitter
connectToTwitter(demoOauth)
# Capture English tweets containing "love" and "hate" for training set
# Note: This could take a few seconds...
train.raw = captureTweets(c("love", "hate"), demoOauth, "", 2000)
# We're only concerned with tweet text
train.raw = parseTweets(train.raw, simplify = T)
train.raw = train.raw[,"text"]
pause()

## Data Pre-processing

## Tweets will contain lots of extra stuff: retweet tags (RT), reply tags (@user), emoji, etc.
## We'll need to clean them up before processing.
# Remove Twitter specific syntax
train = removeTwitterSyntax(train.raw)
# Remove punctuation, digits, and http links
train = cleanTweets(train)
## Since we'll use 'tm' package, we'll convert to a Corpus and clean up a little more
corpus = Corpus(VectorSource(train))
# Convert to lower case, remove stop words, perform stemming, then remove extra white space
corpus = cleanCorpus(corpus)

pause()

## Feature Construction and Selection

# Construct term-document matrix
tdm = TermDocumentMatrix(corpus, control = list(weighting = weightTfIdf, minWordLength = 4, minDocFreq = 1))
#love_assocs = rownames(findAssocs(tdm, "love", 0.2))
#hate_assocs = rownames(findAssocs(tdm, "hate", 0.2))
# Remove sparse terms to reduce feature selection size to a reasonable number

m = as.matrix(tdm)
m.df = as.data.frame(t(m))
#m.df = m.df[, c("love", "hate", love_assocs, hate_assocs)]
m.df = m.df[which(m.df$love >= 1) || which(m.df$hate >= 1),]
m.df$Class = ifelse(m.df$love, "love", "hate")
m.df = factorise(m.df)
traintest = list()
traintest$trainidx = sample(nrow(m.df), size=nrow(m.df)/2)
traintest$trainingset = m.df[traintest$trainidx, ]
traintest$testset = m.df[-traintest$trainidx, ]

pause()

## Modeling and prediction

# We'll use terms that occur 20 or more times as our attributes, excluding love and hate
freq20 = setdiff(findFreqTerms(tdm, 20), c("love", "hate"))
vars = freq20
# Construct the formula, then build the model
formula = as.formula(paste('Class', paste(vars, collapse=' + '), sep=' ~ '))
trainStream = datastream_dataframe(data = traintest$trainingset[,c(vars, "Class")])
hdt = HoeffdingTree(splitConfidence = "1e-1")
hdtTrained = trainMOA(model = hdt, formula, data = trainStream, reset = T)

# Get the predicted classes for the training set
scores = predict(hdtTrained, newdata = traintest$testset[, vars], type="response")
str(scores)
confmx = table(scores, traintest$testset$Class)
accuracy = (confmx[1,1] + confmx[2,2]) / sum(confmx)
sprintf("Accuracy for the test set was %f", accuracy)

# Now use the test set to update the model, given our original formula
testStream = datastream_dataframe(data = traintest$testset[,c(vars, "Class")])
hdtTrained = trainMOA(model = hdt, formula, data = testStream, reset = F)
scores = predict(hdtTrained, newdata = traintest$testset[, vars], type="response")
str(scores)
confmx = table(scores, traintest$testset$Class)
accuracy = (confmx[1,1] + confmx[2,2]) / sum(confmx)
# Show the updated accuracy
sprintf("Updated accuracy for the test set was %f", accuracy)

pause()

##