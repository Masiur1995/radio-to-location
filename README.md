# Camp Fire Radio-to-Location

By **Mitchell Bohman, Nour Zahlan, and Masiur Abik**

Asked to develop a model that would identify and flag people in need of assistance during a catastrophic event, we set out to find live streaming radio scanners with which we could train a model. Our approach was always to find a source for audio, transcribe it, and perform natural language processing on the transcriptions to extract relevant locations. Unable to source a live-streaming API of any kind (Broadcastify is no longer issuing tokens) we decided to use archives. The archives we found (also provided by a premium membership to Broadcastify and it's umbrella company Radio Reference) being nearly complete we were able to set up a simulated scenario: 

Had we been streaming and parsing the radio feeds from Butte County California during the period of November 8 through November 23 of 2018, would we have been able to locate and better mobilize resources to people in need during the Camp Fire?

In reduced technical terms we want to know if we can accurately map locations named in radio transmissions. We will be able to measure accuracy of the transcription, but ultimately, knowing where the camp fire occurred and the contours of its devastation, our map will serve as the true test of our model. 

The steps we take are the following (each of which are presented in their own corresponding `jupyter notebook`):

**1. Audio Processing**(`./1_data_collection_processing`) in which we perform audio signal processing to turn collected audio files into useable samples, and webscrape a cross reference list of locations

**2. Speech Recognition** (`./2_speech_recognition`) where we develop two versions of a call to a Google service using their API to transcribe the speech samples given to it. *NOTE*: To run Google Cloud Speech-to-Text you will require an API key of your own ([found here](https://developers.google.com/maps/documentation/geocoding/get-api-key)).

**3. Named Entity Extraction**(`./3_named_entity_extraction`) using a distinct natural language processing operation and a pretrained model provided by spaCy we extract locations named in the samples.  

**4. Mapping** (`./4_mapping`) again using a Google service we geocode and plot the information extracted  through our transcription and natural language processing

![81fc266d.png](https://github.com/Mbembem/radio-to-location/blob/master/assets/0223f526.png)

## Conclusion

In short, we feel confident in saying that we can parse locations named in radio transmissions with a fair amount of accuracy (on a scale of a region, if not a city). The map we ended up plotting follows the well-documented contours the 2018 Camp Fire quite obviously, with some false positives apparent below it from unrelated events. We were also left feeling like our prototype documented here barely scratched the surface of this project. Given more time and greater computational resources to manage the large quantities of large audio files, this prototype could be elaborated on to provide an important service during catastrophic events. If combined with new practices -- imagine if the professionals deployed during emergency events developed a spoken protocol for naming locations knowing that a similar model was attempting to transcribe and locate the things they named -- it could have significant impact on the way resources are mobilized. Such a model, if implemented adequately, could change the infrastructure for dealing with a wilder world. 