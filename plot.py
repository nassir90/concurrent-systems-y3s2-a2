import matplotlib.pyplot as plt
import numpy as np
from matplotlib.animation import FuncAnimation

class CacheLocalityPlot:
    """
    Supposed to be used with FuncAnimation
    """
    def __init__(self):
        self.figure = plt.figure(figsize=(6, 5))
        self.axes = plt.axes(projection="3d")
        self.xs, self.ys, self.zs = [], [], []
        [self.plot] = self.axes.plot3D([], [], [])
        self.axes.set_title("Cache Locality of Writes to the Dot-Product Accumulator Array")
        self.axes.set_xlabel("Column")
        self.axes.set_ylabel("Row")
        self.axes.set_zlabel("Timestep")
        self.axes.xaxis.get_major_locator().set_params(integer=True)
        self.axes.yaxis.get_major_locator().set_params(integer=True)
        self.axes.zaxis.get_major_locator().set_params(integer=True)

    def init_func(self):
        return self.figure, self.axes, self.plot

    def update_func(self, state):
        self.plot.set_xdata(self.xs)
        self.plot.set_ydata(self.ys)
        self.plot.set_3d_properties(self.zs)
        return self.figure, self.axes, self.plot

    def ingest(self, x: float, y: float, z: float):
        self.xs.append(x)
        self.ys.append(y)
        self.zs.append(z)
        if x > self.axes.get_xlim()[1]:
            self.axes.set_xlim([0, x])
        if y > self.axes.get_ylim()[1]:
            self.axes.set_ylim([0, y])
        if z != 0:
            self.axes.set_zlim([0, z]) # z is nondecreasing

if __name__ == "__main__":
    plot = CacheLocalityPlot()
    CacheLocalityPlot = FuncAnimation(
        plot.figure,
        plot.update_func,
        init_func=plot.init_func,
        cache_frame_data=False
    )
    plt.show(block=False)
    while True:
        try:
            plot.ingest(*map(float, input().split()))
        except EOFError:
            break
        plot.figure.canvas.start_event_loop(0.00001)
