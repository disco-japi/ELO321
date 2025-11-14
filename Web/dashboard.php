<?php require 'base.php'; ?>

<body>
  <div class="container py-5">
    <center>
      <?php
      if ($login) {
        switch ($tab) {
          case 0: ?>
            <div class="container py-5">
            </div>

      <?php break;
          case 1:
            if ($administrador) {
              require 'show.php';
            }
            break;
          case 2:
            if ($administrador) {
              require 'show.php';
            }
            break;
          case 3:
            if ($administrador) {
              require 'show.php';
            }
            break;
          case 4:
            if (!$administrador) {
              require 'show.php';
            }
            break;
          case 5:
            if (!$administrador) {
              require 'show.php';
            }
            break;
          case 6:
            if (!$administrador) {
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