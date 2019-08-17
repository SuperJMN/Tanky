using System;
using System.Reactive.Linq;
using System.Reactive.Subjects;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;

namespace Game1
{
    public class Tanky
    {
        private const int Size = 32;
        private Texture2D walkAnim;
        private Texture2D jump;
        private float baseSpeed = 300F;
        private readonly ISubject<float> speed = new BehaviorSubject<float>(0F);

        public Tanky()
        {
            Width = Size;
            Height = Size;
            Top = 200;

            var distanceAfterLastStop = speed.Scan(0F, (a, b) =>
            {
                if (Sign(a) == Sign(b) || a == 0)
                {
                    return a + b;
                }

                return 0;
            });

            var frameId = distanceAfterLastStop.Select(x => (int) (Math.Abs(x) % 8));
            frameId.Subscribe(i => WalkIndex = i);
        }

        private static int Sign(float f)
        {
            if (Math.Abs(f) < 0.5)
            {
                return 0;
            }

            return f > 0 ? 1 : -1;
        }

        public int Height { get; }

        public int Width { get; }

        public float Top { get; set; }

        public int WalkIndex { get; private set; }
        public float Left { get; private set; }

        public void Load(ContentManager contentManager)
        {
            walkAnim = contentManager.Load<Texture2D>("Tanky");
            jump = contentManager.Load<Texture2D>("Jump");
        }

        public void Draw(SpriteBatch spriteBatch)
        {
            if (Animation == States.Walking || Animation == States.Stopped)
            {
                var destinationRectangle = new Rectangle((int) Left, (int) Top, Width, Height);
                var sourceRectangle = TextureMixin.GetTile(WalkIndex, 0, Size, Size);
                spriteBatch.Draw(walkAnim, destinationRectangle, sourceRectangle, Color.White);
            }
            else if (Animation == States.Jumping)
            {
                var destinationRectangle = new Rectangle((int) Left, (int) Top, Width, Height);
                var sourceRectangle = new Rectangle(0,0, Size, Size);
                spriteBatch.Draw(jump, destinationRectangle, sourceRectangle, Color.White);
            }
        }

        public void GoBack(TimeSpan walkingTime)
        {
            if (Animation != States.Jumping)
            {
                Animation = States.Walking;
            }

            var walkFraction = (float)walkingTime.TotalSeconds;
            Left -= baseSpeed * walkFraction;
            speed.OnNext(-(baseSpeed * walkFraction));
        }

        public void Advance(TimeSpan walkingTime)
        {
            if (Animation != States.Jumping)
            {
                Animation = States.Walking;
            }

            var walkFraction = (float)walkingTime.TotalSeconds;
            
            Left += baseSpeed * walkFraction;
            speed.OnNext(baseSpeed * walkFraction);
        }

        public void Stop()
        {
            if (Animation != States.Jumping)
            {
                Animation = States.Stopped;
            }

            speed.OnNext(0);
        }

        public void Jump()
        {
            Animation = States.Jumping;
        }

        public States Animation { get; set; }
        public float VerticalSpeed { get; set; }

        public enum States
        {
            None,
            Stopped,
            Walking,
            Jumping,
        }

        public void Land()
        {
            this.Animation = States.Stopped;
        }
    }
}