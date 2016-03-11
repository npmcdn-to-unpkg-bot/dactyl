class WebController < ApplicationController
    include ParserHelper
    # METRIC_CATEGORIES = {
    #     readability: [
    #         'flesch_kincaid_reading_ease',
    #         'flesch_kincaid_age_minimum',
    #         'flesch_kincaid_grade_level',
    #         'automated_readability_index',
    #         'coleman_liau_index',
    #         'forcast_grade_level',
    #         'gunning_fog_index',
    #         'smog_grade',
    #         'combined_average_grade_level'
    #     ],

    #     audience: [
    #         'estimated_reading_time'
    #     ],

    #     sentiment: [
    #         'sentiment',
    #         'sentiment_score',
    #         'sentiment_score_per_sentence',
    #         'sentiment_score_per_paragraph',
    #         'positive_words',
    #         'negative_words',
    #         'glittering_generalities'
    #     ],

    #     parts_of_speech: [
    #         'nouns',
    #         'adjectives',
    #         'verbs',
    #         'adverbs',
    #         'conjunctions',
    #         'prepositions',
    #         'pronouns',
    #         'determiners',
    #         'acronyms',
    #         'numbers',
    #         'unrecognized_words'
    #     ],

    #     tone: [
    #         'active_voice_percentage',
    #         'passive_voice_percentage'
    #     ],

    #     abstractions: [
    #         'similes',
    #         'metaphors'
    #     ],

    #     frequencies: [
    #         'acronyms_percentage',
    #         'adjective_percentage',
    #         'auxiliary_verbs_percentage',
    #         'conjunction_percentage',
    #         'determiner_percentage',
    #         'noun_percentage',
    #         'preposition_percentage',
    #         'pronoun_percentage',
    #         'punctuation_percentage',
    #         'repeated_words_percentage',
    #         'special_character_percentage',
    #         'verb_percentage',
    #         'numbers_percentage'
    #     ],

    #     context: [
    #         'language',
    #         'jargon_words',
    #         'related_topics'
    #     ],

    #     analytics: [
    #         'character_count',
    #         'characters_per_word',
    #         'characters_per_sentence',
    #         'characters_per_paragraph',
    #         'digits_per_word',
    #         'consonants_per_word_percentage',
    #         'lexical_density',
    #         'paragraphs', # get paragraph_count
    #         'sentence_count', #rename to sentences
    #         'sentences_per_paragraph',
    #         'spaces_after_sentence',
    #         'syllable_count', #rename to syllables
    #         'syllables_per_word',
    #         'syllables_per_sentence',
    #         'vowels_per_word_percentage',
    #         'unique_words_percentage',
    #         'unique_words_per_sentence',
    #         'unique_words_per_sentence_percentage',
    #         'unique_words_per_paragraph',
    #         'unique_words_per_paragraph_percentage',
    #         'word_count', #rename to words
    #         'words_per_sentence',
    #         'words_per_paragraph',
    #         'whitespace_percentage',
    #     ],

    #     word_frequency_tables: [
    #         'word_frequency_table',
    #         'unique_words',
    #         'repeated_words',
    #         'most_frequent_word',
    #     ],

    #     word_types: [
    #         'complex_words',
    #         'simple_words',
    #         'stem_words',
    #         'stemmed_words',
    #         'filter_words',
    #         'stop_words',
    #         'auxiliary_verbs',
    #         'function_words',
    #         'insert_words',
    #         'lexical_words'
    #     ]
    # }

    def index
        if (params.has_key?(:file) && params[:file].class == ActionDispatch::Http::UploadedFile)
            @analysis_string = parse_document params[:file]
            params[:file].close
        end

        if @analysis_string.present?
            d = Dactylogram.new(data: @analysis_string)
            d.instance_variable_set(:@metrics, params[:metrics].map { |m| "#{m}_metric" }) if params[:metrics].present?
            d.send :calculate_metrics!
            d.save!
            redirect_to show_dactylogram_path(reference: d.reference)
        end
    end

    def upload
        return unless @analysis_string.present?

        d = Dactylogram.new(data: @analysis_string, identifier: params[:author])
        d.instance_variable_set(:@metrics, params[:metrics].map { |m| "#{m}_metric" }) if params[:metrics].present?
        d.send :calculate_metrics!

        #render json: d.save
    end

    def show
        d = Dactylogram.find_by(reference: params[:reference])
        # redirect_to 404 unless d
        @report = d.metric_report
        @report[:metrics] = metrics_by_category @report[:metrics]
    end

    private

    # Categorize all the metrics into groups to avoid printing out one big list to the user
    def metrics_by_category metrics
        # {"FleschKincaidService::grade_level"=>-4.029999999999999, "FleschKincaidService::age_minimum"=>"", "FleschKincaidService::reading_ease"=>121.22000000000003}
        # => 
        # {"FleschKincaidService"=>[{"grade_level"=>-4.029999999999999}, {"age_minimum"=>""}, {"reading_ease"=>121.22000000000003}]}
        categorized_metrics = {}

        metrics.each do |key, value|
            category, method = key.split '::'

            categorized_metrics[category] ||= []
            categorized_metrics[category] << { method => value }
        end

        categorized_metrics
    end

end
