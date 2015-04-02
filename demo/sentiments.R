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

## Next up is data retrieval...

pause()

## Data Retrieval
## We'll capture 2,000 tweets with the words "love" and "hate" in them. Then we'll 
## reduce the data set to just the tweet text. 

pause()

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

## Next is pre-processing...

pause()

## Data Pre-processing

## Tweets will contain lots of extra stuff: retweet tags (RT), reply tags (@user), emoji, etc.
## We'll need to clean them up before processing.

pause()

# Remove Twitter specific syntax
train = removeTwitterSyntax(train.raw)
# Remove punctuation, digits, and http links
train = cleanTweets(train)
## Since we'll use 'tm' package, we'll convert to a Corpus and clean up a little more
corpus = Corpus(VectorSource(train))
# Convert to lower case, remove stop words, perform stemming, then remove extra white space
corpus = cleanCorpus(corpus)

## Now we can construct features...

pause()

## Feature Construction and Selection
## We'll create a term-document matrix describing the frequencies of words in each tweet. 
## We can then use this to select frequent and hopefully valuable features.

pause()

# Construct term-document matrix. We'll leave out wods less than 4 charactors
tdm = TermDocumentMatrix(corpus, control = list(weighting = weightTfIdf, minWordLength = 4, minDocFreq = 1))
# Use the tdm to create a data frame for easier manipulation
m = as.matrix(tdm)
m.df = as.data.frame(t(m))
# We only want to use tweets that contain "love" or "hate " not both.
m.df = m.df[which(m.df$love >= 1) || which(m.df$hate >= 1),]
# Classify the tweets
m.df$Class = ifelse(m.df$love, "love", "hate")
# Factorise for modelling later
m.df = factorise(m.df)
# Now we'll construct the training and testing set. We'll just split the data set in half,
# one half for training and one half for testing
traintest = list()
traintest$trainidx = sample(nrow(m.df), size=nrow(m.df)/2)
traintest$trainingset = m.df[traintest$trainidx, ]
traintest$testset = m.df[-traintest$trainidx, ]

## Now we can build the model...

pause()

## Modeling and prediction
## We'll use a Hoeffding Tree with a split confidence of 1e-1. For features, we'll use 
## words that occur 20 or more times, excluding of course "love" and "hate". We can then
## use the training set to train the model and predict the testing set. The accuracy of
## this is shown. But we can also update the model based on the testing set, using the 
## old features we had previously selected. The updated accuracy using this approach is
## also shown. 

pause()

# We'll use terms that occur 20 or more times as our attributes, excluding love and hate
freq20 = setdiff(findFreqTerms(tdm, 20), c("love", "hate"))
vars = freq20
# Construct the formula, then build the model
formula = as.formula(paste('Class', paste(vars, collapse=' + '), sep=' ~ '))
trainStream = datastream_dataframe(data = traintest$trainingset[,c(vars, "Class")])
# Create the Hoeffding Tree, then train it
hdt = HoeffdingTree(splitConfidence = "1e-1")
hdtTrained = trainMOA(model = hdt, formula, data = trainStream, reset = T)

# Get the predicted classes for the training set
scores = predict(hdtTrained, newdata = traintest$testset[, vars], type="response")
str(scores)
# Create the confusion matrix and calculate accuracy
confmx = table(scores, traintest$testset$Class)
accuracy = (confmx[1,1] + confmx[2,2]) / sum(confmx)
sprintf("Accuracy for the test set was %f", accuracy)

# Now use the test set to update the model, given our original formula
testStream = datastream_dataframe(data = traintest$testset[,c(vars, "Class")])
hdtTrained = trainMOA(model = hdt, formula, data = testStream, reset = F)
scores = predict(hdtTrained, newdata = traintest$testset[, vars], type="response")
str(scores)
# Calculate the updated accuracy
confmx = table(scores, traintest$testset$Class)
accuracy = (confmx[1,1] + confmx[2,2]) / sum(confmx)
# Show the updated accuracy
sprintf("Updated accuracy for the test set was %f", accuracy)

pause()

##