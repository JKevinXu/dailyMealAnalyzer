#!/usr/bin/env python3
"""
Download the Food-101 Vision Transformer model from HuggingFace (nateraw/food)
and convert it to a Core ML model for use in the MealAnalyzer iOS app.

Prerequisites:
    pip install torch torchvision transformers coremltools Pillow

Usage:
    python scripts/create_food_model.py

Output:
    MealAnalyzer/Food101.mlpackage
"""

import sys
import os
import torch
import torch.nn as nn
import numpy as np
from transformers import ViTForImageClassification, ViTImageProcessor
import coremltools as ct

MODEL_NAME = "nateraw/food"
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "MealAnalyzer")
OUTPUT_PATH = os.path.join(OUTPUT_DIR, "Food101.mlpackage")


class Food101Wrapper(nn.Module):
    """Wraps the HuggingFace ViT model to accept raw pixel tensors and output probabilities."""

    def __init__(self, model):
        super().__init__()
        self.model = model

    def forward(self, x):
        outputs = self.model(pixel_values=x)
        return torch.softmax(outputs.logits, dim=-1)


def main():
    print(f"[1/4] Downloading model '{MODEL_NAME}' from HuggingFace...")
    model = ViTForImageClassification.from_pretrained(MODEL_NAME)
    processor = ViTImageProcessor.from_pretrained(MODEL_NAME)
    model.eval()

    # Extract class labels in index order
    num_labels = len(model.config.id2label)
    class_labels = [model.config.id2label[i] for i in range(num_labels)]
    print(f"     Model has {num_labels} food classes.")

    print("[2/4] Tracing PyTorch model...")
    wrapper = Food101Wrapper(model)
    wrapper.eval()

    dummy_input = torch.randn(1, 3, 224, 224)
    traced_model = torch.jit.trace(wrapper, dummy_input)

    # Verify trace
    with torch.no_grad():
        orig_out = wrapper(dummy_input)
        traced_out = traced_model(dummy_input)
        assert torch.allclose(orig_out, traced_out, atol=1e-5), "Trace verification failed!"
    print("     Trace verified successfully.")

    print("[3/4] Converting to Core ML...")

    # The ViT model expects images normalized with mean=0.5, std=0.5
    # CoreML ImageType preprocessing: output = input * scale + bias
    # For [0,255] input -> (x/255 - 0.5)/0.5 = x/127.5 - 1.0
    # So scale = 1/127.5, bias = [-1, -1, -1]
    scale = 1.0 / 127.5

    mlmodel = ct.convert(
        traced_model,
        inputs=[
            ct.ImageType(
                name="image",
                shape=(1, 3, 224, 224),
                scale=scale,
                bias=[-1.0, -1.0, -1.0],
                color_layout="RGB",
            )
        ],
        classifier_config=ct.ClassifierConfig(class_labels),
        convert_to="mlprogram",
        minimum_deployment_target=ct.target.iOS16,
    )

    # Set model metadata
    mlmodel.author = "MealAnalyzer (nateraw/food)"
    mlmodel.short_description = "Food-101 classifier based on Vision Transformer. Identifies 101 types of food from photos."
    mlmodel.license = "Apache 2.0"
    mlmodel.version = "1.0"

    print(f"[4/4] Saving to {OUTPUT_PATH}...")
    mlmodel.save(OUTPUT_PATH)

    size_mb = sum(
        os.path.getsize(os.path.join(dp, f))
        for dp, dn, filenames in os.walk(OUTPUT_PATH)
        for f in filenames
    ) / (1024 * 1024)
    print(f"     Done! Model saved ({size_mb:.1f} MB)")
    print(f"\n     Class labels ({num_labels}):")
    for i, label in enumerate(class_labels):
        print(f"       {i:3d}: {label}")


if __name__ == "__main__":
    main()
