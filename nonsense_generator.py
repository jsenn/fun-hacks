import random

def parse_words(infile):
    """(str) -> dict
    Return a dictionary with the following structure.
    {w1: {f11: c11, f12: c12, ...}, 
     w2: {f21: c21, f22: c22, ...}, 
     ...}, 
    where wi is a unique word in infile and fij is a word which appears directly
    after wi exactly cij times in infile.
    """
    with open(infile) as fid:
        doc = fid.read().split()

    words = {}
    # Go through the words in doc, collecting their follower
    # Ditch the last word, since it doesn't have a follower
    for i in range(len(doc) - 1):
        word = doc[i]
        if word not in words:
            words[word] = {}

        # dict containing follower:count pairs
        followers = words[word]
        next_word = doc[i+1]
        try:
            followers[next_word] += 1
        except KeyError:
            followers[next_word] = 1

    return words

def next_word(followers, ending=False):
    """(dict, bool) -> str
    Randomly return a word from followers, where the probability of a follower
    to be returned is proportional to its count.
    """
    if ending:
        try:
            # list of all words followed by a period
            endings = {f:followers[f] for f in followers if f[-1] == '.'}
            return weighted_choice(endings)
        except AssertionError:
            pass

    return weighted_choice(followers)

def weighted_choice(choices):
    """(dict) -> object
    Adapted from:
    stackoverflow.com/questions/3679694/a-weighted-version-of-random-choice
    """
    total = sum(choices[key] for key in choices)
    r = random.uniform(0, total)
    upto = 0
    for key in choices:
        weight = choices[key]
        if upto + weight > r:
            return key
        upto += weight
    assert False

def generate_text(words, length=10):
    """(dict, int) -> str
    """
    # Find a capital letter
    current_word = random.choice(words.keys())
    while not current_word[0].isupper():
        current_word = random.choice(words.keys())

    output_text = current_word + ' '
    for _ in range(length - 2):
        current_word = next_word(words[current_word])
        output_text += current_word + ' '

    # Find an ending
    while current_word[-1] != '.':
        current_word = next_word(words[current_word], ending=True)
        output_text += current_word + ' '

    return output_text

if __name__ == '__main__':
    infile = '<file_path>'
    words = parse_words(infile)
    print generate_text(words)