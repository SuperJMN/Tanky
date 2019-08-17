using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;

namespace Game1
{
    public class Tanky
    {
        private const int Size = 32;
        private Texture2D walkAnim;
        private float baseSpeed = 400F;

        public Tanky()
        {
            Width = Size;
            Height = Size;
            Top = 400;
        }

        public Vector2 Speed { get; set; }

        public int Height { get; }

        public int Width { get; }

        public float Top { get; set; }

        public int WalkIndex { get; private set; }
        public float Left { get; set; }

        public void Load(ContentManager contentManager)
        {
            walkAnim = contentManager.Load<Texture2D>("Tanky");
        }

        public void Draw(SpriteBatch spriteBatch)
        {
            var destinationRectangle = new Rectangle((int)Left, (int)Top, Width, Height);
            var sourceRectangle = TextureMixin.GetTile(WalkIndex, 0, Size, Size);

            spriteBatch.Draw(walkAnim, destinationRectangle, sourceRectangle, Color.White);

            NextFrame();
        }

        private void NextFrame()
        {
            if (WalkIndex == 7)
            {
                WalkIndex = 0;
            }
            else
            {
                WalkIndex++;
            }
        }

        public void GoBack(TimeSpan walkingTime)
        {
            var walkFraction = (float)walkingTime.TotalSeconds;
            Left -= baseSpeed * walkFraction;
        }

        public void Advance(TimeSpan walkingTime)
        {
            var walkFraction = (float)walkingTime.TotalSeconds;
            Left += baseSpeed * walkFraction;
        }
    }
}