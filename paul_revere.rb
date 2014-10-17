class Array
  def sum
    return self.collect(&:to_f).inject(0){|acc,i|acc +i}
  end
end
class Hash
  ##
  # For any hash, rescue method missing and see if the method being called is a name of a key either as a string or a symbol, then return the value at that point. This could get you into hot water with calls like #values, which is something you could name, but is already taken, which means that the hash[] syntax would have to be used to get that value out.
  def method_missing(method, *args)
    if method.to_s.split("").last == "="
      self[method.to_s.gsub("=", "").to_sym] = args.first
    else
      if (self.keys|[method.to_s,method]).length != 0
        return self.values_at(method, method.to_s).compact.first
      else
        return nil
      end
    end
  end
end
class GEXF
  attr_accessor :file
  ##
  # Create a new GEXF instance.
  #
  # @see http://stackoverflow.com/questions/9886705/how-to-write-bom-marker-to-a-file-in-ruby
  # If you *really* want to learn the spec, go hit the books: {http://gexf.net/1.2draft/gexf-12draft-primer.pdf}
  # @param [String|StringIO|File] file a file to write to
  def initialize(file)
    @file = file
    #This is a Byte Order Mark. Or BOM. Read about it here:
    write("\xEF\xBB\xBF")
  end

  ##
  # Just put some tabs in there for clean lookin' GEXF
  #
  # @param [Fixnum] count number of tabs to write
  def tabs(count)
    return "\t"*count
  end

  ##
  # Write some set of GEXF into the file.
  #
  # @param [String] content the content to write
  def write(content)
    content = content.gsub("&", "&amp;")
    @file.write(content)
  end

  ##
  # Write the header for the GEXF file.
  #
  # @param [Hash] opts specific header declarations - can be omitted.
  def header_declaration(opts={})
    write(%{<gexf xmlns="http://www.gexf.net/1.1draft" xmlns:viz="http://www.gexf.net/1.2draft/viz" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.gexf.net/1.1draft http://www.gexf.net/1.1draft/gexf.xsd" version="1.1">\n\t<creator>#{opts.description || "Graph"}</creator>\n\t<description>#{opts.description || "GEXF"}</description>\n})
  end

  ##
  # Declare basic facts about the type of GEXF we are writing
  #
  # @param [Hash] opts optional changes from the default graph type.
  def graph_declaration(opts={})
    opts[:mode] ||= "static"
    opts[:time_format] ||= "double"
    opts[:default_edge_type] ||= "directed"
    write(%{\t<graph mode="#{opts[:mode]}" timeformat="#{opts[:time_format]}" defaultedgetype="#{opts[:default_edge_type]}">\n})
  end

  ##
  # Write Attributes Declarations (the casting/typing of attributes in GEXFLand)
  #
  # @param [Hash] attributes looks like `{:node => {:static => [{:id => "statuses_count", :title => "Statuses Count", :type => "double"}]}}`
  def attribute_declarations(attributes={})
    attribute_declaration = %{}
    attributes.keys.each do |type|
      attributes[type].each_pair do |mode, attributes|
        attribute_declaration += tabs(2)
        attribute_declaration += %{<attributes class="#{type}" mode="#{mode}">\n}
        attributes.each do |attribute|
          attribute_declaration += tabs(3)
          attribute_declaration += %{<attribute }
          attribute.each_pair do |key, value|
            attribute_declaration += %{#{key}="#{value}" }
          end
          attribute_declaration += %{/>\n}
        end
        attribute_declaration += tabs(2)
        attribute_declaration += %{</attributes>\n}
      end
    end
    write(attribute_declaration)
  end

  ##
  # Write attributes (the actual attribute values)
  #
  # @param [Array] attvalues look like `[{:for => "attribute_name", :value => 1, :start => Time.now-24*60*60*7, :end => Time.now}]`
  def attributes(attvalues=[])
    return "" if attvalues.nil?
    attribute_data = tabs(4)
    attribute_data += %{<attvalues>\n}
    attvalues.each do |attvalue|
      attribute_data += attribute(attvalue)
    end
    attribute_data += tabs(4)
    attribute_data += %{</attvalues>\n}
    return attribute_data
  end

  ##
  # Write a single attribute
  #
  # @param [Hash] attvalue looks like `{:for => "attribute_name", :value => 1, :start => Time.now-24*60*60*7, :end => Time.now}`
  def attribute(attvalue)
    attvalue_gexf = tabs(5)
    attvalue_gexf += %{<attvalue }
    attvalue.each_pair do |key, value|
      attvalue_gexf += %{#{URI.encode(key.to_s)}="#{URI.encode(value.to_s)}" }
    end
    attvalue_gexf += %{/>\n}
    attvalue_gexf
  end

  ##
  # Write edges
  #
  # @param [Array} edges look like: `[{:source => "peat", :target => "dgaff", :start => Time.now-24*60*60*7, :end => Time.now, :attributes => [{:for => "attribute_name", :value => 1, :start => Time.now-24*60*60*7, :end => Time.now}], :slices => [{:start => Time.now-24*60*60*7, :end => Time.now}]}]`
  def edges(edges)
    edges.compact.each do |edge|
      edge(edge)
    end
  end

  ##
  # Write Edge
  #
  # @param [Hash] edge looks like: `{:source => "peat", :target => "dgaff", :start => Time.now-24*60*60*7, :end => Time.now, :attributes => [{:for => "attribute_name", :value => 1, :start => Time.now-24*60*60*7, :end => Time.now}], :slices => [{:start => Time.now-24*60*60*7, :end => Time.now}]}`
  def edge(edge)
    edge_data = tabs(3)
    edge_data += %{<edge source="#{edge[:source]}" target="#{edge[:target]}"}
    (edge_data += %{ start="#{edge[:start]}"}) if edge[:start]
    (edge_data += %{ end="#{edge[:end]}"}) if edge[:start]
    edge_data += %{>\n}
    edge_data += attributes(edge[:attributes])
    edge_data += tabs(3)
    edge_data += %{</edge>\n}
    write(edge_data)
  end

  ##
  # Write nodes
  #
  # @param [Array] nodes look like: `[{:id => "peat", :label => "Peat Bakke", :start => Time.now-24*60*60*7, :end => Time.now, :attributes => [{:for => "attribute_name", :value => 1, :start => Time.now-24*60*60*7, :end => Time.now}], :slices => [{:start => Time.now-24*60*60*7, :end => Time.now}]}]`
  def nodes(nodes)
    nodes.each do |node|
      node(node)
    end
  end


  ##
  # Write node
  #
  # @param [Hash] node looks like `{:id => "peat", :label => "Peat Bakke", :start => Time.now-24*60*60*7, :end => Time.now, :attributes => [{:for => "attribute_name", :value => 1, :start => Time.now-24*60*60*7, :end => Time.now}], :slices => [{:start => Time.now-24*60*60*7, :end => Time.now}]}`
  def node(node)
    node_data = tabs(3)
    node_data += %{<node id="#{node[:id]}" label="#{node[:label].to_s.gsub('"', "&quot;")}"}
    (node_data += %{ start="#{node[:start]}"}) if node[:start]
    (node_data += %{ end="#{node[:end]}"}) if node[:start]
    node_data += %{>\n}
    node_data += attributes(node[:attributes])
    node_data += viz(node.viz)
    node_data += tabs(3)
    node_data += %{</node>\n}
    write(node_data)
  end

  ##
  # Write all viz attributes
  #
  # @param [Hash] node_viz looks like `{size: 10, color: {r: 20, g: 200, b: 42}, position: {x: 1, y: 100, z: 0}}`
  def viz(node_viz)
    return "" if node_viz.nil?
    size(node_viz) + position(node_viz) + color(node_viz)
  end

  ##
  # Write Size for node if node has size specified
  #
  # @param [Hash] node_viz looks like `{size: 10, color: {r: 20, g: 200, b: 42}, position: {x: 1, y: 100, z: 0}}`
  def size(node_viz)
    return "" if node_viz[:size].nil? && node_viz["size"].nil?
    %{\t\t\t\t<viz:size value="#{node_viz[:size] || node_viz["size"]}"></viz:size>\n}
  end

  ##
  # Write Position for node if node has size specified
  #
  # @param [Hash] node_viz looks like `{size: 10, color: {r: 20, g: 200, b: 42}, position: {x: 1, y: 100, z: 0}}`
  def position(node_viz)
    return "" if node_viz.position.x.nil? || node_viz.position.y.nil?
    %{\t\t\t\t<viz:position x="#{node_viz.position.x}" y="#{node_viz.position.y}" z="#{node_viz.position.z||0.0}"></viz:position>\n}
  end

  ##
  # Write Color for node if node has size specified
  #
  # @param [Hash] node_viz looks like `{size: 10, color: {r: 20, g: 200, b: 42}, position: {x: 1, y: 100, z: 0}}`
  def color(node_viz)
    return "" if node_viz.color.r.nil? || node_viz.color.g.nil? || node_viz.color.b.nil?
    %{\t\t\t\t<viz:color r="#{node_viz.color.r}" g="#{node_viz.color.g}" b="#{node_viz.color.b}"></viz:color>\n}
  end

  ##
  # And we're out
  def footer
    write(%{\t</graph>\n</gexf>\n})
  end
end
require 'open-uri'
require 'csv'

class Graph
  def self.from_paul_revere_kieran_healy
    data = CSV.parse(open("https://raw.githubusercontent.com/kjhealy/revere/master/data/PaulRevereAppD.csv"))
    groups = data.first[1..-1]
    revolutionaries = data.collect(&:first)[1..-1]
    graph = {nodes: [], edges: []}
    revolutionaries.each do |r|
      graph[:nodes] << {id: r.split(".").reverse.join(" "), label: r.split(".").reverse.join(" "), :attributes => [{:for => "type", :value => "Revolutionary"}]}
    end
    groups.each do |g|
      graph[:nodes] << {id: g.split(/(?=[A-Z])/).join(' '), label: g.split(/(?=[A-Z])/).join(' '), :attributes => [{:for => "type", :value => "Group"}]}
    end
    data[1..-1].each do |membership_set|
      revolutionary = membership_set.first.split(".").reverse.join(" ")
      membership_set[1..-1].each_with_index do |m, i|
        next if m.to_i == 0
        graph[:edges] << {source: revolutionary, target: groups[i].split(/(?=[A-Z])/).join(' ')}
      end
    end
    self.new(graph)
  end

  def self.from_paul_revere_kieran_healy_bipartite_projection
    data = CSV.parse(open("https://raw.githubusercontent.com/kjhealy/revere/master/data/PaulRevereAppD.csv"))
    revolutionaries = data.collect(&:first)[1..-1]
    graph = {nodes: [], edges: []}
    revolutionaries.each do |r|
      graph[:nodes] << {id: r.split(".").reverse.join(" "), label: r.split(".").reverse.join(" "), :attributes => [{:for => "type", :value => "Revolutionary"}]}
    end
    data[1..-1].each do |membership_set|
      revolutionary = membership_set.first.split(".").reverse.join(" ")
      data[1..-1].each do |alter_set|
        alter_revolutionary = alter_set.first.split(".").reverse.join(" ")
        strength = [membership_set[1..-1].collect(&:to_i), alter_set[1..-1].collect(&:to_i)].transpose.collect(&:sum).select{|x| x == 2}.length
        next if revolutionary == alter_revolutionary || strength == 0
          graph[:edges] << {:source => revolutionary, :target => alter_revolutionary, :attributes => [{:for => "weight", :value => strength}]}
      end
    end
    self.new(graph)
  end

  def to_gexf(file=StringIO.new("", "w+"))
    gexf = GEXF.new(file)
    gexf.header_declaration;false
    gexf.graph_declaration;false
    gexf.attribute_declarations(attribute_declarations);false
    gexf.nodes(@nodes);false
    gexf.edges(@edges);false
    gexf.footer;false
    gexf.file.rewind
    gexf.file
  end

  def initialize(graph)
    @nodes = graph.nodes
    @edges = graph.edges
  end

  def attribute_declarations
    {node: {static: [{:id => "type", :title => "Type", :type => "String"}]}, edge: {static: [{:id => "weight", :title => "Weight", :type => "double"}]}}
  end

  def gexf_type(class_to_s)
    {
      "Float" => "double",
      "FalseClass" => "boolean",
      "TrueClass" => "boolean",
      "Array" => "string",
      "Hash" => "string",
      "String" => "string",
      "NilClass" => "string",
    }[class_to_s]
  end
end
(gexf = (g = Graph.from_paul_revere_kieran_healy).to_gexf(File.open("paul_revere.gexf", "w")))
(gexf = (g = Graph.from_paul_revere_kieran_healy_bipartite_projection).to_gexf(File.open("paul_revere_projection.gexf", "w")))
