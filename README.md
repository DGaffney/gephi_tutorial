Additional notes from the presentation: 

# CSV Import

Included in this package are two different examples of how to import CSV files into Gephi. Note that the rows are separated by new lines, and the columns are split by commas. Note an important thing: Gephi is not so smart, so we have to wrap each cell (in Excel parlance) with a double quote so that it's crystal clear what the file is doing. In practice, you need to make sure that each cell is wrapped with quote marks to make it crystal clear. 

# Exporting

I forgot to note the purpose of the "Preview" tab on the top. After you have a layout that you're happy with, the Preview tab is where you setup your final view of the graph. This view brings up two panels, the "Preview Settings" and "Preview" panels. In the "Preview Settings" tab, select the "Default Curved" option as a starting point, and edit the options below to tweak your layout and figure out the options that you'll have. Any manipulation of the graph requires that you click the "Refresh" button at least once (sometimes twice) in order to view the final layout. If you fail to click the "Refresh" button before exporting images (eg SVG/PDF/PNG), you'll only get an empty graph.