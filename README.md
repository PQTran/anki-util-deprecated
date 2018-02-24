# Anki Utility
## Motivation
To automate the creation of anki vocabulary sets.
We will want to make the format consistent with the
existing deck, to provide a uniform studying experience.
By decreasing the difficulty and time it takes to
create vocabulary sets, I can better focus on learning the
content.

## Workflow
* Create a new card-set based on the template csv
  The fields will consist of: char, pinyin, meaning, etc, notes
* Execute the multi-stage bash script
  Downloads audio
  Updates the csv to reference the audio file
  Copy all audio to correct Anki directory

## Implementation
### Considerations
Deal with each stage completely, then proceed to next.
Error handling of previous stage failing must be considered.

Stages:
Gather data from csv (store in variables)
- input: input file
- parse column
Download all audio (attempt)
- input: pinyin_words, output dir
- break up pin1yin1 words into syllables
- create a temporary column with the pronunciation tones
- given 3rd tone 3rd tone, replace with 2nd tone 3rd tone (confusing for future steps)
- error handling: if some downloads fail, log failures
Combine audio
- consider: 1-2+ audio
- error handling: files does not exist, log failure
Create new csv based on old csv
- update reading column pin1yin1 with pīnyīn
- update sound column with [sound:file-name.mp3]
- consider: missing combined file -> do not update sound column
- error handling: log
Move all combined audio file to anki audio file

### Dependencies
mp3wrap - combines mp3 tool
[Export anki deck to csv](https://ankiweb.net/shared/info/1112021968)

