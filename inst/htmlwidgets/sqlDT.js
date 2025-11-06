HTMLWidgets.widget({

  name: 'sqlDT',

  type: 'output',

  factory: function(el, width, height) {

    // Filter obj, returning a new obj containing only
    // values with keys in keys.
    var filterKeys = function(obj, keys) {
      var result = {};
      keys.forEach(function(k) {
        if (obj.hasOwnProperty(k))
          result[k]=obj[k];});
      return result;
    };

    return {

      renderValue: function(x) {

        // Transpose the data from column-oriented to row-oriented
        var data = x.data;
        var data_keys = Object.keys(data);
        // Check if there are crosstalk keys provided
        if (x.settings.crosstalk_key != null) {
          var row_keys = x.settings.crosstalk_key;
        } else {
          // Otherwise generate row keys as serial numbers
          var row_keys = [];
          for (var i=0; i<data[data_keys[0]].length; i++) {
            row_keys.push(i.toString());
          }
        }
        var transpose_data = {};
        for (var i=0; i<row_keys.length; i++) {
          transpose_data[row_keys[i]] = {};
          for (var j=0; j<data_keys.length; j++) {
            transpose_data[row_keys[i]][data_keys[j]] = data[data_keys[j]][i];
          }          
        }

        // Update the display to show the values in data
        var update = function(data) {
          // Replace the keys in data with serial numbers
          var new_data = [];
          var data_keys = Object.keys(data);
          for (var i=0; i<data_keys.length; i++) {
            new_data[i] = data[data_keys[i]];
          }
          var result = alasql(x.settings.query, [new_data]);

          table_id = 'dataTable-' + Math.floor(Math.random() * 1000000000);

          // Clear the existing contents of el and add a table element
          $(el).html('<table id="' + table_id + '" class="display" style="width:100%"></table>');

          // Create an array for the columns definition for DataTables for the result table
          var columns = [];
          if (result.length > 0) {
            var result_keys = Object.keys(result[0]);
            for (i=0; i<result_keys.length; i++) {
              columns.push({data: result_keys[i], title: result_keys[i]});
            }
          }
          
          // Initialize the DataTable
          $('#' + table_id).DataTable(
            $.extend(true, {}, x.settings.options, {
              data: result,
              columns: columns
            })
          );
          
        };

        // Set up to receive crosstalk filter and selection events
        var ct_filter = new crosstalk.FilterHandle();
        ct_filter.setGroup(x.settings.crosstalk_group);
        ct_filter.on("change", function(e) {
          if (e.value) {
            update(filterKeys(transpose_data, e.value));
          } else {
            update(transpose_data);
          }
        });

        var ct_sel = new crosstalk.SelectionHandle();
        ct_sel.setGroup(x.settings.crosstalk_group);
        ct_sel.on("change", function(e) {
          if (e.value && e.value.length) {
            update(filterKeys(transpose_data, e.value));
          } else {
            update(transpose_data);
          }
        });

        update(transpose_data);

      },

      resize: function(width, height) {

        // TODO: code to re-render the widget with a new size

      }

    };
  }
});
