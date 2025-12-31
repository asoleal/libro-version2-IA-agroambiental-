# Ajuste de Modelos: Cuando el Sistema no es Perfecto {#chap:regresion_lineal}

En el capítulo anterior, asumimos que nuestros sensores eran perfectos y que podíamos encontrar una solución exacta para $A\mathbf{x}=\mathbf{b}$. Sin embargo, en un campo de cultivo real, dos plantas con la misma cantidad de agua y nutrientes pueden crecer diferente debido a factores aleatorios (genética, viento, plagas).

Aquí entramos en el terreno de la \*\*Ciencia de Datos\*\*: rara vez buscamos una solución exacta (que no existe); buscamos la \*\*mejor solución aproximada\*\*.

## Intuición: El Problema del Sistema Sobredeterminado

Imagina que quieres predecir el rendimiento de maíz ($y$) basándote en la cantidad de Nitrógeno aplicado ($x$). Tomas 100 muestras en el campo. Esto genera un sistema de ecuaciones con 100 ecuaciones (una por muestra) pero solo 2 incógnitas (la pendiente y la intersección de la recta: $y = mx + c$).

$$\begin{bmatrix}
x_1 & 1 \\
x_2 & 1 \\
\vdots & \vdots \\
x_{100} & 1
\end{bmatrix}
\begin{bmatrix}
m \\
c
\end{bmatrix}
=
\begin{bmatrix}
y_1 \\
y_2 \\
\vdots \\
y_{100}
\end{bmatrix}$$

Matemáticamente, esto es una matriz $A$ alta y delgada ($100 \times 2$). Es un sistema \*\*sobredeterminado\*\*. No existe una línea recta que pase exactamente por los 100 puntos a la vez. El vector $\mathbf{b}$ no vive en el espacio columna de $A$.

## Formalización: Ecuaciones Normales

Ya que no podemos hacer que el error sea cero, tratamos de que sea lo más pequeño posible. Definimos el error (residuo) como la distancia entre lo que predice nuestro modelo ($A\hat{\mathbf{x}}$) y la realidad ($\mathbf{b}$):

$$\mathbf{e} = \mathbf{b} - A\hat{\mathbf{x}}$$

Para minimizar la longitud de este vector de error ($||\mathbf{e}||^2$), utilizamos cálculo o geometría proyectiva para llegar a las famosas \*\*Ecuaciones Normales\*\*:

<div class="admonition tip"><p class="admonition-title">🌿 La Ecuación Maestra del Machine Learning Clásico</p> La mejor aproximación $\hat{\mathbf{x}}$ se encuentra resolviendo: $$A^T A \hat{\mathbf{x}} = A^T \mathbf{b}$$ </div>

Nota que $A^T A$ es una matriz cuadrada y simétrica, lo que (casi siempre) nos permite resolver el sistema.

## Conexión Agro-Mecatrónica

<details class="example"><summary><strong>Aplicación: Calibración de Sensores de Humedad Capacitivos</strong></summary><div class="details-content"> Los sensores de humedad de suelo baratos devuelven un voltaje analógico. Para convertir ese voltaje a \"Porcentaje de Humedad Volumétrica\", necesitamos calibrarlos. 1. Tomamos muestras de suelo con humedades conocidas (10%, 20%, \..., 50%). 2. Medimos el voltaje en cada muestra. 3. Usamos Mínimos Cuadrados para encontrar la ecuación $Humedad = m \cdot Voltaje + c$ que minimice el error de lectura. </div></details>

## Implementación: Predicción de Rendimiento

Vamos a usar datos simulados para encontrar la relación entre agua de riego y producción de biomasa usando las Ecuaciones Normales (sin librerías de caja negra primero) y luego validando con Scikit-Learn.

``` {caption="Cálculo de Regresión Lineal 'desde cero' usando Álgebra Lineal"}
import numpy as np

# 1. DATOS DE CAMPO (Simulados)
# X: Litros de agua/semana, y: Kg de biomasa
X_raw = np.array([10, 15, 20, 25, 30, 35])
y = np.array([1.2, 1.8, 2.5, 3.1, 3.4, 4.0])

# 2. CONSTRUCCIÓN DE LA MATRIZ DE DISEÑO A
# Necesitamos agregar una columna de 1s para el término independiente (intercepto)
# A tendrá forma (6 filas, 2 columnas)
ones = np.ones(len(X_raw))
A = np.column_stack((X_raw, ones))

print("Matriz A (Diseño):")
print(A[:3]) # Mostramos solo las primeras 3 filas

# 3. ECUACIONES NORMALES: (A^T * A) * x = (A^T * b)
# Paso A: Calcular A transpuesta por A
At_A = np.dot(A.T, A)

# Paso B: Calcular A transpuesta por y
At_y = np.dot(A.T, y)

# Paso C: Resolver el sistema lineal cuadrado resultante
# Usamos np.linalg.solve (que usa Descomposición LU internamente)
theta = np.linalg.solve(At_A, At_y)

pendiente = theta[0]
intercepto = theta[1]

# 4. PREDICCIÓN
agua_nueva = 40 # Litros
prediccion = pendiente * agua_nueva + intercepto
```



    Matriz A (Diseño):
    [[10.  1.]
     [15.  1.]
     [20.  1.]]
     
    Modelo encontrado:
    Biomasa = 0.110 * Agua + 0.205

    Predicción para 40L de agua:
    4.62 Kg de biomasa

<div class="admonition warning"><p class="admonition-title">Atención: Correlación no implica Causalidad</p> Un $R^2$ alto en nuestro modelo matemático no significa que el agua sea la única causa del crecimiento. Si ignoramos plagas o temperatura, el modelo fallará en producción real. El álgebra lineal no tiene sentido común biológico. </div>
