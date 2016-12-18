require 'natto'

class TfIdf
  include Math

  attr_reader :texts, :nm, :word_count, :tf, :idf, :tfidf, :tfidf_corpus

  def initialize(*text)
    @texts = text
    @nm = Natto::MeCab.new
    @tf = {}
    @idf = {}
    @tfidf = {}
    @tfidf_corpus = {}
    @word_count ||= 0
  end

  # TF = (単語数 / 総単語数) を求める
  def term_frequency
    texts.each do |text|
      nm.parse(text) do |n|
        if n.feature =~ /名詞/
          tf[n.surface] ? tf[n.surface] += 1 : tf[n.surface] = 1
          @word_count += 1
        end
      end
    end
    tf.each { |key, value| tf[key] = bigdecimal(value.to_f / word_count.to_f) }
  end

  # IDF = log(文書の総数/単語が現れた文書の数)
  def inverse_document_frequency
    tf.each do |key, _|
      idf[key] ||= 0
      texts.each { |text| idf[key] += 1 if text.include?(key) }
    end
    idf.each { |key, value| idf[key] = bigdecimal(log(texts.size.to_f / value.to_f, 10)) }
  end

  # TF-IDF = TF * IDF
  def tf_idf
    tf.each do |tf_k, tf_v|
      idf_v = idf[tf_k]
      tfidf[tf_k] = bigdecimal(tf_v * idf_v)
    end
    tfidf
  end

  # { "文書" => [単語のtfidf値, ..] }
  def tf_idf_courpus
    texts.each do |text|
      tfidf_values = []
      tfidf.each do |tfidf_k, tfidf_v|
        text.include?(tfidf_k) ? tfidf_values << tfidf_v : tfidf_values << 0.0
      end
      tfidf_corpus[text] = tfidf_values
    end
    tfidf_corpus
  end

  private

  def bigdecimal(result)
    BigDecimal(result.to_s).floor(5).to_f
  end
end

t = TfIdf.new('和風きのこスパゲッティとは和風スパゲッティの一種主にキノコをメインにした和風のソースで作られる日本のパスタ料理', 'あんかけスパゲッティは愛知県名古屋市で登場したスパゲッティ料理略称はあんかけスパあんかけパスタと呼ばれる事はあまりない')
t.term_frequency
t.inverse_document_frequency
t.tf_idf.sort_by { |_, v| -v }[0..5].each { |w| w }
t.tf_idf_courpus

### TF-IDFを用いたCos類似度

a_tfidf, b_tfidf = t.tfidf_corpus.values
p a_tfidf.delete(0)
p b_tfidf.delete(0)

a = Math.sqrt(a_tfidf.inject { |sum, n| sum + n * n })
b = Math.sqrt(b_tfidf.inject { |sum, n| sum + n * n })
p [a_tfidf, b_tfidf].transpose.map { |n| n.inject(:*) }.inject(:+) / (a * b)
