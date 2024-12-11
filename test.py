import torch

a = torch.tensor([[0, 0, 2, 1],
                  [0, 0, 2, 1]])
print(a[:, :3])
a[:, :3] += torch.tensor([[0, 0, 0], [-1, 0, 0]])
print(a)
