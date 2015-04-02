Mitchell Neville

CSC 591 P3

# twitter-sentimentsR

## Introduction

This project seeks to classify tweets from Twitter's stream using R. Tweets 
containing the words "love" and "hate" are pulled from the stream, and a model
is built to classify these tweets based on their text content. The 
classification is binary with "love" and "hate" being the two classes. 

## Running the Project

### Environment

This project requires a working R ver. >= 3.1.3 environment, and it has been 
targeted for Linux platforms. 

### Required Packages

This project requires the following packages:

- streamR
- ROAuth
- tm
- SnowballC
- devtools
- ff
- rJava
- RMOA
- rpart
- ROCR

### Running the Demo

The project comes in the form of a package so that the ````demo()```` command
can be used to demonstrate the classification techniques used. In order to run
the demo, the package must be installed. Having R installed, you can build the
package and install it as follows:

1. Download the zip containing the project and extract it. 
2. Navigate to the extracted folder ````twitter-sentimentsR```` in a console 
and run:
````
R CMD check twitter-sentimentsR
````
This will check that the package can be built. Note that the folder name may 
be different depending on how you have obtained the zip; however, this folder 
should be the folder containing the ````data````, ````demo````, ````R````, etc
folders. 
3. After validating the package, build it:
````
R CMD build twitter-sentimentsR
````
This should build a tar.gz file that can be used for installation. 
4. In R Studio, for example, install the package. This may require changing
the working directory to the proper folder, which can be done using ````setwd()````.

```` R
> install.packages(<path to package>, repos=NULL, type="source")
> require("twitterSentimentsR")
````
5. Having successfully installed the package, you can run the "sentiments"
demonstration:
```` R
> demo(sentiments, "twitterSentimentsR")
````

### Interpreting the Results

The demonstration will walk through the steps and explain them, but in 
essence, the demonstration does the following:

1. Data Retrieval
    - streamR is used to connect to the Twitter streaming API. A working 
Twitter consumer key and consumer secret are required for this step. The 
application will ask for these in order to connect.
    - Tweets containing "love" and "hate" are pulled in. 
2. Pre-processing
    - Twitter-specific syntax ("RT", "@someuser", etc.) are removed from text
    - Punctuation, digits, and links are removed
    - The tm package is used to create a corpus and remove stop words,
perform stemming, and remove extra white space.
3. Feature Creation and Selection
    - A term-document matrix is created from the corpus, and it is further
refined.
    - The corpus is converted to a data frame, and classifications are
applied. 
    - Training and testing data sets are extracted from the data frame.
    - A list of frequent terms are pulled as features. 
4. Modelling and Prediction
    - A Hoeffding Tree is created for the model.
    - The attributes are used along with the training set to train the model. 
After this, the test set is used to evaluate the model and display it's 
accuracy. 
    - The Hoeffding Tree's model is then updated using the training set, and
the updated accuracy of the model is shown. 
