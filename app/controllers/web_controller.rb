class WebController < ApplicationController

    skip_before_filter :verify_authenticity_token, :only => [:index]

    METRIC_CATEGORIES = {
        readability: [
            'automated_readability_index',
            'coleman_liau_index',
            'flesch_kincaid_age_minimum',
            'flesch_kincaid_grade_level',
            'flesch_kincaid_reading_ease',
            'forcast_grade_level',
            'gunning_fog_index',
            'smog_grade',
            'combined_average_grade_level'
        ],

        analytics: [
            'data_length',
            'characters_per_word',
            'characters_per_sentence',
            'characters_per_paragraph',
            'letters_per_word',
            'digits_per_word',
            'consonants_per_word',
            'consonants_per_word_percentage',
            'vowels_per_word_percentage', #nonpercentage?
            'syllable_count', #rename to syllables
            'syllables_per_word',
            'syllables_per_sentence',
            'word_count', #rename to words
            'words_per_sentence',
            'words_per_paragraph',
            'unique_words_percentage',
            'unique_words_per_sentence',
            'unique_words_per_sentence_percentage',
            'unique_words_per_paragraph',
            'unique_words_per_paragraph_percentage',
            'paragraphs', # get paragraph_count
            'sentence_count', #rename to sentences
            'sentences_per_paragraph',
            'spaces_after_sentence',
            'whitespace_percentage',
        ],

        frequencies: [
            'conjunction_frequency',
            'determiner_frequency_percentage',
            'preposition_frequency',
            'pronoun_frequency',
            'punctuation_percentage',
            'repeated_words_percentage',
            'special_character_percentage',
        ],

        word_frequency_tables: [
            'word_frequency_table',
            'unique_words',
            'repeated_words',
            'most_frequent_word',
            'word_tree'
        ],

        sentiment: [
            'sentiment'
        ]
    }

    def index
        return unless @analysis_string.present?

        d = Dactylogram.new(data: @analysis_string)
        d.instance_variable_set(:@metrics, params[:metrics].map { |m| "#{m}_metric" }) if params[:metrics].present?

        @report = d.metric_report
        @report[:metrics] = metrics_by_category @report[:metrics]
    end

    # Categorize all the metrics into groups to avoid printing out one big list to the user
    def metrics_by_category metrics
        categorized_metrics = {}
        METRIC_CATEGORIES.keys.each do |category|
            categorized_metrics[category] = metrics.slice *METRIC_CATEGORIES[category]
        end
        categorized_metrics
    end

end
