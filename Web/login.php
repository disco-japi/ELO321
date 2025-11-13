<?php
session_start();
session_unset();
session_destroy();
?>
<?php require 'base.php'; ?>

<body>
  <div class="container col-xl-10 col-xxl-8 px-4 py-5">
    <div class="row align-items-center g-lg-5 py-5">
      <div class="col-lg-7 text-center text-lg-start">
        <h1 class="display-4 fw-bold lh-1 text-body-emphasis mb-3">
          TeleFactory
        </h1>
        <p class="col-lg-10 fs-4">
          Inicie sesión para comprar insumos tecnológicos.
        </p>
      </div>
      <div class="col-md-10 mx-auto col-lg-5">
        <form class="p-4 p-md-5 border rounded-3 bg-body-tertiary" action="dashboard.php" method="POST" onsubmit="return validate();">
          <div class="form-floating mb-3">
            <input
              type="text"
              required
              class="form-control"
              id="username"
              name="username"
              placeholder="Nombre de usuario" />
            <label for="username">Nombre de usuario</label>
          </div>
          <div class="form-floating mb-3">
            <input
              type="password"
              required
              class="form-control"
              id="passwd"
              name="passwd"
              placeholder="Contraseña" />
            <label for="passwd">Contraseña</label>
          </div>
          ¿Que rol cumples?<br>
          <input type="radio" class="form-check-input" id="usr" name="rol" value="Usuario" checked="true">
          <label for="usr">Usuario</label><br>
          <input type="radio" class="form-check-input" id="ing" name="rol" value="Ingeniero">
          <label for="ing">Ingeniero</label><br>
          <button class="w-100 btn btn-lg btn-primary" type="submit">
            Iniciar sesión
          </button>
          <hr class="my-4" />
          <small class="text-body-secondary">¿No estas registrado? <a href="register.php">Registrate</a></small>
          <p id=error style="color:red;"></p>
        </form>
      </div>
    </div>
  </div>

</body>
<?php require 'footer.php'; ?>

</html>