<?php require 'base.php'; ?>

<body>
  <div class="container py-5">
    <center>
      <?php
      if ($login) {
        switch ($tab) {
          case 0: ?>
            <div class="container py-5">
              <div class="row flex-lg-row-reverse align-items-center g-5 py-5">
                <div class="col-10 col-sm-8 col-lg-6">
                  <img
                    src="https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Fthescalers.com%2Fwp-content%2Fuploads%2F2023%2F03%2FTop-programming-languages.jpg"
                    class="d-block mx-lg-auto img-fluid"
                    alt="Bootstrap Themes"
                    width="700"
                    height="500"
                    loading="lazy" />
                </div>
                <div class="col-lg-6">
                  <h1 class="display-5 fw-bold text-body-emphasis lh-1 mb-3">
                    Página principal
                  </h1>
                  <p class="lead">
                    Te damos la bienvenida al dashboard de ZeroPressure. Desde aquí podrás <?php $text = $ingeniero ? "realizar gestión de solicitudes, y revisar cuales estan asignadas a ti" : "revisar el estado de tus solicitudes, y redactar solicitudes nuevas";
                                                                                            echo $text; ?>.
                  </p>
                </div>
              </div>
            </div>

      <?php break;
          case 1:
            if ($ingeniero) {
              require 'show.php';
            }
            break;
          case 2:
            if ($ingeniero) {
              require 'show.php';
            }
            break;
          case 3:
            if ($ingeniero) {
              require 'show.php';
            }
            break;
          case 4:
            if (!$ingeniero) {
              require 'show.php';
            }
            break;
          case 5:
            if (!$ingeniero) {
              require 'show.php';
            }
            break;
          case 6:
            if (!$ingeniero) {
              require 'request.php';
            }
            break;
          case 7:
            require 'show.php';
            break;
          case 8:
            require 'show.php';
            break;
        }
      } ?>
    </center>
  </div>
</body>
<?php require 'footer.php'; ?>

</html>