function flipImage(btn) {
    var img = $(btn).closest('.document-card').find('img, canvas')[0]
    img.style.transform = 'scaleX(-1) ' + img.style.transform;
}

function rotateImage(btn) {
    var img = $(btn).closest('.document-card').find('img, canvas')[0]
    img.style.transform = 'rotate(90deg) ' + img.style.transform;
}

function galleryView() {
    $('.document-gallery-view').show()
    $('.data-table').hide()
    $('.document-view-switcher .list-button').removeClass('button--primary')
    $('.document-view-switcher .gallery-button').addClass('button--primary')
    localStorage.setItem('document-view', 'gallery');
}

function listView() {
    $('.document-gallery-view').hide()
    $('.data-table').show()
    $('.document-view-switcher .list-button').addClass('button--primary')
    $('.document-view-switcher .gallery-button').removeClass('button--primary')
    localStorage.setItem('document-view', 'list');
}

// wait until page load
document.addEventListener("DOMContentLoaded",  function() {
    const documentView = localStorage.getItem('document-view');
    if (documentView === 'gallery') {
        galleryView()
    } else {
        listView()
    }
    // Loaded via <script> tag, create shortcut to access PDF.js exports.
    var pdfjsLib = window['pdfjs-dist/build/pdf'];

    // The workerSrc property shall be specified.
    pdfjsLib.GlobalWorkerOptions.workerSrc = '//mozilla.github.io/pdf.js/build/pdf.worker.js';

    // check if images are actually PDFs, if so, load them into canvas.
    document.querySelectorAll('img').forEach(image => {
        image.addEventListener('error', function() {
            var url = image.src;
            $.ajax({
                type: 'HEAD',
                url: url,
                complete: function(xhr) {
                    var mime = xhr.getResponseHeader('Content-Type');
                    if (mime === "application/pdf") {
                        var canvas = document.createElement("canvas");
                        var pageControl = document.createElement("span");
                        pageControl.classList.add("pdf-page-control");
                        canvas.height = image.parentElement.clientHeight;
                        image.parentElement.prepend(canvas);
                        image.parentElement.prepend(pageControl);
                        image.remove();
                        loadPdf(url, canvas);
                    }
                }
            });
        });
    })

    $('.document-edit-form-inline form').on('ajax:success', function(e, data, status, xhr){
        // because the page doesn't reload, need to update the list view to match
        var newType = $(this).find("select#document_document_type option:selected").val();
        var newName = $(this).find("input#document_display_name").val();
        var newYear = $(this).find("select#document_tax_return_id option:selected").text();
        // find the corresponding row in the list view table
        var documentId = $(this).closest('.document-card').attr('id');
        var tableRowCells = $(`.data-table #${documentId} td`);
        tableRowCells.eq(0).text(newType);
        tableRowCells.eq(1).find('a').text(newName);
        tableRowCells.eq(2).text(newYear);

        // make the Save button indicate that it was saved
        $(this).find('button').text('Saved').addClass('form-success');
        // revert to "Save" after 3 seconds
        setTimeout(() => {
            $(this).find('button').text('Save').removeClass('form-success');
        }, 3000);
      }).on('ajax:error',function(e, xhr, status, error){
        // if error, show red "Error" on button
        $(this).find('button').text('Error').css('background-color', 'red');
      });
});

// Page control to go to next or previous page in PDF
function makePageControl(canvas, pdf) {
    var pageControl = $(canvas).siblings('.pdf-page-control');
    var text = `Page ${canvas.dataset.page}/${pdf.numPages}`;
    pageControl.text(text);
    var nextArrow = $('<a>').text(' \u{25ba}').on('click', function() {
        canvas.dataset.page++;
        text = `Page ${canvas.dataset.page}/${pdf.numPages}`;
        pageControl.text(text);
        renderPage(canvas, pdf);
    });
    var backArrow = $('<a>').text('\u{25c4} ').on('click', function() {
        canvas.dataset.page--;
        text = `Page ${canvas.dataset.page}/${pdf.numPages}`;
        pageControl.text(text);
        renderPage(canvas, pdf);
    });
    if (canvas.dataset.page < pdf.numPages) 
        pageControl.append(nextArrow);
    if (canvas.dataset.page > 1)
        pageControl.prepend(backArrow);
    return pageControl;
}

// Render a PDF page in the canvas
function renderPage(canvas, pdf) {
    var pageNumber = Number(canvas.dataset.page);
    pdf.getPage(pageNumber).then(function (page) {
        var viewport = page.getViewport({ scale: 1 });

        // Prepare canvas using PDF page dimensions
        var desiredWidth = window.innerWidth * 0.245;
        canvas.width = desiredWidth;
        var scale = desiredWidth / viewport.width;
        var scaledViewport = page.getViewport({ scale: scale });
        canvas.height = scaledViewport.height;

        // Render PDF page into canvas context
        var context = canvas.getContext("2d");
        var renderContext = {
          canvasContext: context,
          viewport: scaledViewport
        };
        var renderTask = page.render(renderContext);
        renderTask.promise.then(function () {
            var pageControl = makePageControl(canvas, pdf)
            $(pageControl).insertAfter(canvas);
        });
      });
}

// Load a PDF from a URL into a canvas. Note that in production, cross-origin
// will need to be properly set up to work on the Hub.
function loadPdf(url, canvas) {
    var loadingTask = pdfjsLib.getDocument(url);
    loadingTask.promise.then(
      function (pdf) {
        // Fetch the first page
        canvas.dataset.page = 1;
        renderPage(canvas, pdf);
      },
      function (reason) {
        // PDF loading error
        console.error("ERROR " + JSON.stringify(reason));
      }
    );
  }