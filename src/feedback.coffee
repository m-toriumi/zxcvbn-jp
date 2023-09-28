scoring = require('./scoring')

feedback =
  default_feedback:
    warning: ''
    suggestions: [
      "数個の単語を組み合わせて、一般的なフレーズを避けてください。"
      "記号、数字、大文字を必ずしも含む必要はありません。"
    ]

  get_feedback: (score, sequence) ->
    # starting feedback
    return @default_feedback if sequence.length == 0

    # no feedback if score is good or great.
    return if score > 2
      warning: ''
      suggestions: []

    # tie feedback to the longest match for longer sequences
    longest_match = sequence[0]
    for match in sequence[1..]
      longest_match = match if match.token.length > longest_match.token.length
    feedback = @get_match_feedback(longest_match, sequence.length == 1)
    extra_feedback = '簡単なフレーズを避けてください。'
    if feedback?
      feedback.suggestions.unshift extra_feedback
      feedback.warning = '' unless feedback.warning?
    else
      feedback =
        warning: ''
        suggestions: [extra_feedback]
    feedback

  get_match_feedback: (match, is_sole_match) ->
    switch match.pattern
      when 'dictionary'
        @get_dictionary_match_feedback match, is_sole_match

      when 'spatial'
        layout = match.graph.toUpperCase()
        warning = if match.turns == 1
          'キーボード上の文字をqwertyのように直線的に使うのを避けてください。'
        else
          'キーボード上で隣接する文字を繰り返すパターンは避けてください。'
        warning: warning
        suggestions: [
          'キーボードで文字を選ぶときは単純な直線や繰り返しを避け、より複雑な順番で文字を選んでください。'
        ]

      when 'repeat'
        warning = if match.base_token.length == 1
          '「aaa」のような繰り返しは推測しやすいです。'
        else
          '「abcabcabc」のような繰り返しは、「abc」よりもわずかに推測されにくいだけです。'
        warning: warning
        suggestions: [
          '繰り返される単語や文字を避けてください。'
        ]

      when 'sequence'
        warning: "「abc」や「6543」のような並びは簡単に推測されます。"
        suggestions: [
          '連続する文字や数字を避けてください。'
        ]

      when 'regex'
        if match.regex_name == 'recent_year'
          warning: "近代の西暦は推測されやすいです。"
          suggestions: [
            '近代の西暦を避けてください。'
            'あなたに関連する西暦を使用するのは避けてください。'
          ]

      when 'date'
        warning: "日付は推測されやすいです。"
        suggestions: [
          'あなたに関連する日付を使用するのは避けてください。'
        ]

  get_dictionary_match_feedback: (match, is_sole_match) ->
    warning = if match.dictionary_name == 'passwords'
      if is_sole_match and not match.l33t and not match.reversed
        if match.rank <= 10
          'これは最もよく使われるパスワードTOP10に含まれるパスワードです。'
        else if match.rank <= 100
          'これは最もよく使われるパスワードTOP100に含まれるパスワードです。'
        else
          'これは非常によく使われるパスワードです。'
      else if match.guesses_log10 <= 4
        'これはよく使われるパスワードに似ています。'
    else if match.dictionary_name == 'english_wikipedia'
      if is_sole_match
        '単語のみは推測されやすいです。'
    else if match.dictionary_name in ['surnames', 'male_names', 'female_names']
      if is_sole_match
        '名前や名字単体は推測されやすいです'
      else
        '一般的な名前と名字は推測されやすいです。'
    else
      ''

    suggestions = []
    word = match.token
    if word.match(scoring.START_UPPER)
      suggestions.push "先頭の文字を大文字にすることには意味はありません。"
    else if word.match(scoring.ALL_UPPER) and word.toLowerCase() != word
      suggestions.push "すべて大文字はすべて小文字と同じくらい推測されやすいです。"

    if match.reversed and match.token.length >= 4
      suggestions.push "逆さにした単語も推測されやすいです。"
    if match.l33t
      suggestions.push "予測可能な置換（例: 'a' の代わりに '@' 等）はあまり役立ちません"

    result =
      warning: warning
      suggestions: suggestions
    result

module.exports = feedback
